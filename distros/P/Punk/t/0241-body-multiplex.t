#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use POSIX ();

# A request body with no CONTENT_LENGTH, which is what a multiplexed
# transport sends.
#
# HTTP/1.1 has two ways to frame a body: a declared length, or
# `Transfer-Encoding: chunked`. HTTP/2 and HTTP/3 have neither - both forbid
# the header outright and frame the body in the protocol - so a client that
# streams an upload sends a bodied request carrying no framing header at all.
#
# Punk used to read that combination as "there is no body" and answer 200 with
# nothing, and `max_body` used to read it as "nothing to check" and impose no
# ceiling at all. Both were correct rules for HTTP/1 and wrong from HTTP/2 on.
# What resolves it is `psgix.input.buffered`: a server that sets it is holding
# a finite body already, so reading to EOF terminates.
#
# A refusal is a response plus a close while the client is still writing a
# body nobody wants - the first write gets ECONNRESET and the second raises
# SIGPIPE, which kills the test file after every assertion in it has passed.
$SIG{PIPE} = 'IGNORE';

our ($SAW, $ERR, $COUNT);

{
    package MApp;
    use Punk;

    max_body 4096;

    # ->body: the whole thing, which is how nearly every application reads it
    post '/echo' => sub {
        my $c = shift;
        $c->text('got:' . length($c->req->body // ''));
    };
    # ->json, which goes through ->body and so shares its framing decision
    post '/json' => sub {
        my $c = shift;
        my $j = $c->req->json;
        $c->text('name:' . (ref $j eq 'HASH' ? ($j->{name} // '?') : '?'));
    };
    # the chunked reader, which has its own copy of the decision
    post '/each' => sub {
        my $c = shift;
        $main::COUNT = $c->req->body_each(sub { $main::SAW .= $_[0] });
        $c->text("count:$main::COUNT");
    };
    # the route that switches the ceiling off, to prove the ceiling is what
    # refuses the one above rather than the read simply stopping
    post '/nolimit' => sub {
        my $c = shift;
        $c->text('got:' . length($c->req->body // ''));
    }, { max_body => 0 };

    package main;
}

my $app = MApp->to_app;

# One request, spelled the way a server that buffers its input spells it.
# `buffered` off is the HTTP/1 live socket; `clen` undef is the multiplexed
# request with nothing declared.
sub call {
    my (%o) = @_;
    my $body = defined $o{body} ? $o{body} : '';
    open my $in, '<', \$body or die "open: $!";
    my $env = {
        REQUEST_METHOD  => 'POST',
        PATH_INFO       => $o{path},
        QUERY_STRING    => '',
        SERVER_NAME     => 'localhost',
        SERVER_PORT     => 80,
        SERVER_PROTOCOL => $o{proto} // 'HTTP/2',
        HTTP_HOST       => 'localhost',
        'psgi.url_scheme' => 'http',
        'psgi.input'    => $in,
        'psgi.errors'   => \*STDERR,
        CONTENT_TYPE    => $o{type} // 'application/octet-stream',
        (defined $o{clen} ? (CONTENT_LENGTH => $o{clen}) : ()),
        ($o{buffered} ? ('psgix.input.buffered' => 1) : ()),
        ($o{te} ? (HTTP_TRANSFER_ENCODING => $o{te}) : ()),
    };
    my $res = $app->($env);
    my $out = ref $res->[2] eq 'ARRAY' ? join('', @{ $res->[2] }) : '';
    return ($res->[0], $out);
}

# ---- the bug: a buffered body with nothing declared --------------------------

{
    my ($st, $out) = call(path => '/echo', body => 'hello-h2', buffered => 1);
    is($st, 200, 'a bodied request with no CONTENT_LENGTH is served');
    is($out, 'got:8', 'and the application sees the body');
}

{
    my ($st, $out) = call(path => '/json', type => 'application/json',
                          body => '{"name":"multiplexed"}', buffered => 1);
    is($out, 'name:multiplexed', '->json reads it too');
}

{
    local ($SAW, $COUNT) = ('', 0);
    my ($st, $out) = call(path => '/each', body => 'abcdefghij', buffered => 1);
    is($out, 'count:10', 'body_each reads it in chunks');
    is($SAW, 'abcdefghij', 'and the chunks are the body');
}

# ---- and HTTP/1 is untouched -------------------------------------------------
#
# Same request without the buffered flag: a live socket, where reading to EOF
# is how an application hangs. Nothing is read, and - the part that matters -
# it is not an error either, because this is also the shape of an ordinary
# bodyless POST.

{
    my ($st, $out) = call(path => '/echo', body => 'hello', proto => 'HTTP/1.1');
    is($st, 200, 'an unbuffered request with no framing header is still served');
    is($out, 'got:0', '...and still reads nothing: it does not go looking');
}

{
    my ($st, $out) = call(path => '/echo', body => 'hello', clen => 5,
                          proto => 'HTTP/1.1');
    is($out, 'got:5', 'a declared length reads exactly that many bytes');
}

{
    my ($st, $out) = call(path => '/echo', body => 'hello-hello', clen => 5,
                          buffered => 1, proto => 'HTTP/1.1');
    is($out, 'got:5', '...and no more, even when more is there to read');
}

{   # chunked on a server that does not buffer: still the refusal it was.
    # There is no length to read to and the handle is live, so the chunked
    # reader says so rather than hanging - which is what it did before this
    # file existed, and the one case where Transfer-Encoding still decides.
    local ($SAW, $COUNT) = ('', 0);
    my ($st, $out) = call(path => '/each', body => 'hello', te => 'chunked',
                          proto => 'HTTP/1.1');
    is($st, 500, 'chunked with no psgix.input.buffered is refused');
    like($out, qr/reading to EOF on a live socket would hang/,
         '...naming why, rather than hanging');
}

# ---- max_body, on the request it could not check up front --------------------
#
# There is no declared length to compare against, so the ceiling cannot answer
# before the read. It bounds the read instead: the bytes stop arriving at the
# ceiling and the request is refused, rather than the whole of an unbounded
# body being handed to a handler that asked for at most 4096.

{
    my $big = 'x' x 20_000;
    my ($st, $out) = call(path => '/echo', body => $big, buffered => 1);
    is($st, 500, 'an undeclared body over max_body is refused');
    like($out, qr/passed 4096 bytes/, '...naming the ceiling it passed');
    isnt($out, 'got:20000', '...rather than being read unbounded');
}

{   # the same body, on a route that switched the ceiling off
    my $big = 'x' x 20_000;
    my ($st, $out) = call(path => '/nolimit', body => $big, buffered => 1);
    is($out, 'got:20000',
       'max_body => 0 on the route reads it whole, so the ceiling is what refused');
}

{   # a declared length is still refused up front, before any read
    my ($st, $out) = call(path => '/echo', body => 'x', clen => 20_000,
                          buffered => 1);
    is($st, 413, 'a declared length over the ceiling is still a 413');
}

{
    local ($SAW, $COUNT) = ('', 0);
    my ($st, $out) = call(path => '/each', body => 'y' x 20_000, buffered => 1);
    is($st, 500, 'body_each is bounded by max_body as well');
    cmp_ok(length $SAW, '<=', 4096 + 65536,
       '...having read no more than the ceiling plus the window it was in');
}

# ---- the whole thing, against a real HTTP/2 server ---------------------------
#
# The synthetic environment above is Punk's half of the contract. This is the
# other half: that Hyperman really does present an h2 request this way, and
# that a client really does send one.

SKIP: {
    my $skip = 5;
    eval { require Hyperman; 1 } or skip 'Hyperman required', $skip;
    skip 'Hyperman built without nghttp2', $skip unless Hyperman->has_http2;
    my $curl = `which curl 2>/dev/null`;
    chomp $curl;
    skip 'curl not found', $skip unless $curl;
    skip 'curl lacks HTTP/2', $skip
        unless `curl --version 2>/dev/null` =~ /\bHTTP2\b/;
    require IO::Socket::INET;

    # An ephemeral port the kernel just handed out, not one derived from $$:
    # two runs whose pids agree modulo the span pick the same number, and the
    # second one then talks to the first one's server.
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp',
        Listen => 5, ReuseAddr => 1);
    skip 'no free loopback port', $skip unless $sock;
    my $port = $sock->sockport;
    close $sock;

    my $pid = fork;
    skip "fork: $!", $skip unless defined $pid;
    if (!$pid) {
        # Nothing in the child may hold the harness's TAP pipe, or `make test`
        # hangs on a read that never sees EOF. Test::Builder dups it into its
        # own handles at load, so those are closed too, and the alarm is the
        # backstop for a child nobody reaps.
        open STDOUT, '>', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;
        if (my $tb = eval { Test::Builder->new }) {
            for my $h (eval { $tb->output }, eval { $tb->failure_output },
                       eval { $tb->todo_output }) {
                close $h if defined $h;
            }
        }
        alarm 60;
        # $app, not a second MApp->to_app: an app compiles once and the
        # second call croaks "already compiled", which in a child whose
        # STDERR is /dev/null is a server that silently never listens
        Hyperman->run(app => $app, host => '127.0.0.1',
                      port => $port, workers => 1, http2 => 1);
        POSIX::_exit(0);
    }

    for (1 .. 50) {
        my $c = IO::Socket::INET->new(PeerAddr => "127.0.0.1:$port");
        last if $c;
        select undef, undef, undef, 0.1;
    }

    # -T - uploads from stdin, whose length curl cannot know, so it sends the
    # body in DATA frames with no content-length header. That is precisely the
    # request this file is about, and there is no way to spell it in HTTP/1.1
    # without Transfer-Encoding.
    my $stream = sub {
        my ($path, $body) = @_;
        open my $fh, '-|',
            "printf %s '$body' | curl -s -o - -w '\\n%{http_code}' "
          . "--http2-prior-knowledge -X POST -T - "
          . "-H 'Content-Type: application/octet-stream' "
          . "'http://127.0.0.1:$port$path' 2>/dev/null"
            or return (0, '');
        my $out = do { local $/; <$fh> };
        close $fh;
        my ($code) = $out =~ /(\d+)\s*\z/;
        $out =~ s/\n?\d+\s*\z//;
        return ($code // 0, $out);
    };

    {
        my ($code, $out) = $stream->('/echo', 'body-over-h2');
        is($code, 200, 'an h2 POST with an unknown-length body is served');
        is($out, 'got:12', '...and the application receives the body');
    }

    {
        my ($code, $out) = $stream->('/nolimit', 'x' x 20_000);
        is($out, 'got:20000', 'a large h2 body arrives whole where nothing caps it');
    }

    {   # the ceiling, on the wire. Named exactly rather than "not 200": a
        # connection that never happened answers 000, which is also not 200,
        # and would let this pass while proving nothing.
        my ($code, $out) = $stream->('/echo', 'x' x 20_000);
        is($code, 500, 'an h2 body over max_body is refused, not read unbounded');
        like($out, qr/passed 4096 bytes/, '...naming the ceiling it passed');
    }

    kill 'TERM', $pid;
    waitpid $pid, 0;
}

done_testing;

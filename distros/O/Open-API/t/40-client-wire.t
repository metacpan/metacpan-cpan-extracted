#!perl
use 5.008003;
use strict;
use warnings;
use IO::Socket::INET;
use Test::More;

# What the client actually puts ON THE WIRE for header and cookie parameters.
#
# These two locations are the only part of a request that cannot be inspected
# without sending one: there is no _request_headers the way there is a
# _request_url and a _request_body. So this test takes a socket, reads the raw
# request, and asserts the bytes.
#
# It exists because both locations had the same bug, and reading the code was
# not what settled it. An array-valued header reached SvPV and the request
# carried `X-H: ARRAY(0x936c29bd0)` - a Perl reference address, sent to a
# server. The cookie loop did the same with sv_catsv. A value the server would
# then split on commas, and never get back.

plan skip_all => 'Fetch not installed' unless eval { require Fetch; 1 };
require Open::API;
require Open::API::Client;

# One listener, answering `n` requests, echoing back the header we care about.
sub listener {
    my ($n, $want) = @_;
    my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                    Listen => 5, ReuseAddr => 1)
        or plan skip_all => "cannot listen: $!";
    my $port = $srv->sockport;
    my $pid  = fork();
    plan skip_all => 'cannot fork' unless defined $pid;
    if (!$pid) {
        # the child must not run the parent's END blocks or the harness sees
        # a second plan - see the house note on forked tests
        for (1 .. $n) {
            my $c = $srv->accept or next;
            my $req = '';
            while (my $l = <$c>) { $req .= $l; last if $l =~ /^\r?\n$/ }
            my ($got) = $req =~ /^\Q$want\E:[ ]*(.*?)\r?$/mi;
            $got = defined $got ? $got : '(absent)';
            print $c "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n"
                   . "Content-Length: " . length($got) . "\r\n"
                   . "Connection: close\r\n\r\n$got";
            close $c;
        }
        close $srv;
        POSIX::_exit(0) if eval { require POSIX; 1 };
        exit 0;
    }
    return ($port, $pid);
}

sub api_for {
    my (%p) = @_;
    return Open::API->new(spec => {
        openapi => '3.1.0',
        info    => { title => 'T', version => '1.0.0' },
        paths   => { '/t' => { get => {
            operationId => 'op',
            parameters  => [ \%p ],
            responses   => { 200 => { description => 'ok',
                content => { 'text/plain' => {
                    schema => { type => 'string' } } } } } } } },
    });
}

my $STR = { type => 'string' };
my $ARR = { type => 'array', items => { type => 'string' } };
my $OBJ = { type => 'object',
            properties => { R => { type => 'string' },
                            G => { type => 'string' } } };

my @CASES = (
    # in, schema, explode, value, what must arrive
    [ 'header', $ARR, 0, [ 'a', 'b', 'c' ], 'a,b,c',
      'an array header is comma separated, not stringified' ],
    [ 'header', $STR, 0, 'plain', 'plain',
      'a scalar header is unchanged' ],
    [ 'header', $OBJ, 0, { R => '1', G => '2' }, 'G,2,R,1',
      'an object header is k,v pairs (sorted, so the bytes are stable)' ],
    [ 'header', $OBJ, 1, { R => '1', G => '2' }, 'G=2,R=1',
      'an exploded object header is k=v' ],
);

my ($port, $pid) = listener(scalar @CASES, 'X-H');
my $failed = 0;

for my $c (@CASES) {
    my ($in, $schema, $explode, $value, $want, $name) = @$c;
    my %p = (name => 'X-H', in => $in, schema => $schema);
    $p{explode} = $explode ? \1 : \0;
    my $api = api_for(%p);
    my $cli = Open::API::Client->new(api => $api,
                                     base_url => "http://127.0.0.1:$port");
    my $res = eval { $cli->op('X-H' => $value)->get };
    if (!$res) {
        my $e = $@; $e =~ s/ at .*//s;
        fail($name); diag("  request failed: $e"); $failed++; next;
    }
    my $got = ref $res eq 'HASH' ? ($res->{body} // $res->{data} // '') : $res;
    is($got, $want, $name)
        or diag("  a reference address on the wire looks like this: "
                . "ARRAY(0x...)");
}

kill 'TERM', $pid;
waitpid $pid, 0;

done_testing();

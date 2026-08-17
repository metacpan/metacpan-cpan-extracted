#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Socket ();

# $c->ua: the shared outbound agent. What matters here is the lifecycle, not
# Fetch itself - one agent per worker so the keep-alive pool survives between
# requests, a fresh one after a fork so two workers never share sockets, and
# the worker's loop underneath it when there is one.

BEGIN {
    plan skip_all => 'Fetch required for $c->ua' unless eval { require Fetch; 1 };
}

{
    package UaApp;
    use Punk;
    ua timeout => 7, agent => 'punk-test/1';
    get '/class' => sub { my ($c) = @_; $c->text(ref $c->ua) };
    get '/addr'  => sub { my ($c) = @_; $c->text(0 + $c->ua) };
    get '/twice' => sub { my ($c) = @_; $c->text($c->ua == $c->ua ? 'same' : 'differ') };
    1;
}

my $app = UaApp->to_app;

sub hit {
    my ($path) = @_;
    my $body = '';
    open my $in, '<', \$body or die;
    my $r = $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => $path, QUERY_STRING => '',
        SCRIPT_NAME => '', 'psgi.url_scheme' => 'http', HTTP_HOST => 'x',
        'psgi.input' => $in, CONTENT_LENGTH => 0,
    });
    return $r->[2][0];
}

# ---- it is a Fetch, and the keyword's options reached it --------------------
is(hit('/class'), 'Fetch', '$c->ua is a Fetch agent');
is(hit('/twice'), 'same',  'the same object twice within one request');

# ---- shared across requests -------------------------------------------------
# The whole point: an agent owns a keep-alive pool and DNS state, so building
# one per request would throw both away.
{
    my $first  = hit('/addr');
    my $second = hit('/addr');
    is($second, $first, 'the same agent serves the next request too');
}

# ---- a fork gets its own ----------------------------------------------------
# An agent built before a fork would leave every worker sharing one set of
# sockets. punk_ua.h keeps the pid beside the agent for exactly this.
SKIP: {
    skip 'no real fork on this platform', 1 if $^O eq 'MSWin32';
    my $parent = hit('/addr');
    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) { print hit('/addr'); exit 0 }
    my $child = do { local $/; <$rd> };
    close $rd;
    isnt($child, $parent, 'a forked worker builds its own agent, not the parent\'s');
}

# ---- it really fetches ------------------------------------------------------
# Outside a Hyperman worker there is no loop to bind to, so Fetch falls back to
# its own and ->get blocks. That is the documented degradation, and it is what
# makes $c->ua usable from a test at all.
SKIP: {
    my $srv;
    socket($srv, Socket::PF_INET(), Socket::SOCK_STREAM(), 0) or skip 'no socket', 2;
    setsockopt($srv, Socket::SOL_SOCKET(), Socket::SO_REUSEADDR(), 1);
    bind($srv, Socket::pack_sockaddr_in(0, Socket::inet_aton('127.0.0.1')))
        or skip 'no bind', 2;
    listen($srv, 5) or skip 'no listen', 2;
    my $port = (Socket::unpack_sockaddr_in(getsockname $srv))[0];

    my $pid = fork;
    skip 'no fork', 2 unless defined $pid;
    if (!$pid) {                       # a one-shot HTTP server
        if (accept(my $cl, $srv)) {
            my $req = '';
            while (sysread($cl, my $b, 4096)) { $req .= $b; last if $req =~ /\r\n\r\n/ }
            # echo back the User-Agent, so the test can prove the ua keyword's
            # options reached the actual request rather than just the object
            my ($seen) = $req =~ /^User-Agent:[ \t]*(.*?)\r\n/mi;
            my $body = defined $seen ? $seen : '(none)';
            syswrite($cl, "HTTP/1.1 200 OK\r\nContent-Length: " . length($body)
                        . "\r\nConnection: close\r\n\r\n$body");
            close $cl;
        }
        exit 0;
    }
    close $srv;

    {
        package UaApp2;
        use Punk;
        ua agent => 'punk-test/1';
        get '/proxy' => sub {
            my ($c) = @_;
            my $res = $c->ua->get($c->req->param('u'))->get;
            $c->text($res->content);
        };
        1;
    }
    my $app2 = UaApp2->to_app;
    my $body = '';
    open my $in, '<', \$body or die;
    my $r = $app2->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/proxy',
        QUERY_STRING => "u=http://127.0.0.1:$port/", SCRIPT_NAME => '',
        'psgi.url_scheme' => 'http', HTTP_HOST => 'x',
        'psgi.input' => $in, CONTENT_LENGTH => 0,
    });
    is($r->[0], 200, 'a handler can fetch through $c->ua');
    is($r->[2][0], 'punk-test/1',
       'the ua keyword options reach the wire (upstream saw the User-Agent)');
    waitpid $pid, 0;
}

# ---- cookie_jar => 1 isolates per request -----------------------------------
# A jar belongs to the agent, so a jar on the worker-shared agent would be
# shared by every request that worker serves. With `ua cookie_jar => 1` each
# request gets a clone with its own jar - over the same pool, so isolation is
# not paid for with the connection.
{
    package JarApp;
    use Punk;
    ua cookie_jar => 1;
    # The handlers pin what they address: a freed clone's memory is the
    # allocator's to hand straight back, so comparing the addresses of two
    # DEAD objects can legally find them equal (a smoker did). Held alive,
    # distinct objects must have distinct addresses.
    our @keep;
    get '/j' => sub { my ($c) = @_; push @keep, $c->ua->cookie_jar; $c->text(0 + $keep[-1]) };
    get '/a' => sub { my ($c) = @_; push @keep, $c->ua; $c->text(0 + $keep[-1]) };
    1;
}
{
    my $japp = JarApp->to_app;
    my $get = sub {
        my $body = ''; open my $in, '<', \$body or die;
        my $r = $japp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
            QUERY_STRING => '', SCRIPT_NAME => '', 'psgi.url_scheme' => 'http',
            HTTP_HOST => 'x', 'psgi.input' => $in, CONTENT_LENGTH => 0 });
        return $r->[2][0];
    };
    isnt($get->('/j'), $get->('/j'),
         'cookie_jar => 1 gives each request its own jar');
    isnt($get->('/a'), $get->('/a'),
         '...on its own agent, so the jar cannot outlive the request');
}

# ---- cookie_jar => 'shared' is the deliberate opt-out ------------------------
{
    package SharedJarApp;
    use Punk;
    ua cookie_jar => 'shared';
    get '/j' => sub { my ($c) = @_; $c->text(0 + $c->ua->cookie_jar) };
    1;
}
{
    my $sapp = SharedJarApp->to_app;
    my $get = sub {
        my $body = ''; open my $in, '<', \$body or die;
        my $r = $sapp->({ REQUEST_METHOD => 'GET', PATH_INFO => '/j',
            QUERY_STRING => '', SCRIPT_NAME => '', 'psgi.url_scheme' => 'http',
            HTTP_HOST => 'x', 'psgi.input' => $in, CONTENT_LENGTH => 0 });
        return $r->[2][0];
    };
    is($get->(), $get->(),
       "cookie_jar => 'shared' keeps one jar across requests, as asked");
}

# ---- more than one agent ----------------------------------------------------
# Two upstreams rarely want the same timeout, headers or jar, so `ua` names a
# second the way `database` does, and $c->ua($name) asks for it. Each name gets
# its own agent, so they share neither a pool nor a set of defaults.
{
    package MultiApp;
    use Punk;
    ua timeout => 30;                                   # the default
    ua partner => { agent => 'partner/1' };
    ua billing => { agent => 'billing/1', cookie_jar => 1 };
    our @keep;   # pin per-request clones: see JarApp above
    get '/d'  => sub { my ($c) = @_; $c->text(0 + $c->ua) };
    get '/p'  => sub { my ($c) = @_; $c->text(0 + $c->ua('partner')) };
    get '/b'  => sub { my ($c) = @_; push @keep, $c->ua('billing'); $c->text(0 + $keep[-1]) };
    get '/pp' => sub { my ($c) = @_; $c->text($c->ua('partner') == $c->ua('partner') ? 'same' : 'differ') };
    get '/x'  => sub { my ($c) = @_; eval { $c->ua('nope') }; $c->text($@ || 'no croak') };
    1;
}
{
    my $mapp = MultiApp->to_app;
    my $get = sub {
        my $body = ''; open my $in, '<', \$body or die;
        my $r = $mapp->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0],
            QUERY_STRING => '', SCRIPT_NAME => '', 'psgi.url_scheme' => 'http',
            HTTP_HOST => 'x', 'psgi.input' => $in, CONTENT_LENGTH => 0 });
        return $r->[2][0];
    };

    my ($d, $p, $b) = ($get->('/d'), $get->('/p'), $get->('/b'));
    isnt($p, $d, 'a named agent is not the default one');
    isnt($b, $p, 'and two named agents are distinct');

    is($get->('/p'), $p, 'a named agent is shared across requests, like the default');
    is($get->('/pp'), 'same', 'and memoised within one request');

    # the per-request jar is a property of the name, not of the application
    isnt($get->('/b'), $b, "a named agent with cookie_jar => 1 still clones per request");

    like($get->('/x'), qr/not a configured agent/,
         'asking for an undeclared agent croaks and names it');
}

done_testing;

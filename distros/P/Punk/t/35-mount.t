#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;

# `mount '/legacy' => $psgi_app`: handing a prefix to any other PSGI
# application. The keyword is a documented one-liner, but the contract behind
# it is not - where it sits in the dispatch order, what the mounted app sees in
# its env, and what it does *not* get from the framework around it.

# Every mounted app records the env it was handed, so the rewriting can be
# checked from the outside rather than trusted.
my @SEEN;

sub psgi_app {
    my ($name) = @_;
    return sub {
        my ($env) = @_;
        push @SEEN, { name => $name, map { $_ => $env->{$_} }
                      qw(SCRIPT_NAME PATH_INFO REQUEST_METHOD QUERY_STRING) };
        return [ 200, [ 'Content-Type', 'text/plain', 'X-From', $name ],
                 [ "$name:" . ($env->{PATH_INFO} // '') ] ];
    };
}

{
    package Mounts;
    use Punk;

    mount '/legacy'      => main::psgi_app('legacy');
    mount '/legacy/deep' => main::psgi_app('deep');
    mount '/bare'        => main::psgi_app('bare');

    # a static route on a mounted prefix, to prove which wins
    get '/legacy/exact' => sub { $_[0]->text('native exact') };
    # a dynamic route that would also match under the mount
    get '/bare/:thing'  => sub { $_[0]->text('native dynamic') };
    get '/'             => sub { $_[0]->text('root') };
}

my $app = Mounts->to_app;

sub hit {
    my (%a) = @_;
    @SEEN = ();
    open my $in, '<', \($a{body} // '');
    my $env = {
        REQUEST_METHOD => $a{method} // 'GET',
        PATH_INFO      => $a{path},
        QUERY_STRING   => $a{query} // '',
        SERVER_NAME    => 'localhost', SERVER_PORT => 80,
        HTTP_HOST      => 'localhost', 'psgi.url_scheme' => 'http',
        'psgi.input'   => $in,
    };
    $env->{SCRIPT_NAME} = $a{script} if defined $a{script};
    my $res = $app->($env);
    return ($res, $env);
}

sub body { my ($r) = @_; return join '', map { $_ // '' } @{ $r->[2] } }

# ---- it dispatches at all ------------------------------------------------------

{
    my ($res) = hit(path => '/legacy/orders');
    is($res->[0], 200, 'a request under a mount is served');
    is(body($res), 'legacy:/orders', 'by the mounted application');
    my %h = @{ $res->[1] };
    is($h{'X-From'}, 'legacy',
        'and the mounted app owns the response headers');
    is(scalar @SEEN, 1, 'the mounted app was called exactly once');
}

# ---- what the mounted app is handed --------------------------------------------

{
    my ($res) = hit(path => '/legacy/orders/7', query => 'page=2');
    is($SEEN[0]{PATH_INFO}, '/orders/7',
        'PATH_INFO has the prefix stripped');
    is($SEEN[0]{SCRIPT_NAME}, '/legacy',
        'SCRIPT_NAME carries the prefix, so the app can build its own URLs');
    is($SEEN[0]{QUERY_STRING}, 'page=2', 'the query string is untouched');
}

{   # the mount's own root: PSGI wants a PATH_INFO, not an empty string
    my ($res) = hit(path => '/legacy');
    is($SEEN[0]{PATH_INFO}, '/',
        'a request for the prefix itself arrives as /');
    is($SEEN[0]{SCRIPT_NAME}, '/legacy', 'with the prefix in SCRIPT_NAME');
}

{   # already mounted somewhere: the prefix appends rather than replaces
    my ($res) = hit(path => '/legacy/x', script => '/outer');
    is($SEEN[0]{SCRIPT_NAME}, '/outer/legacy',
        'an existing SCRIPT_NAME is extended, not overwritten');
    is($SEEN[0]{PATH_INFO}, '/x', 'and PATH_INFO is still the remainder');
}

{   # the rewrite is scoped to the call: the caller's env comes back intact,
    # which matters to any server or middleware that reads it afterwards
    my ($res, $env) = hit(path => '/legacy/x', script => '/outer');
    is($env->{PATH_INFO}, '/legacy/x', 'the caller\'s PATH_INFO is restored');
    is($env->{SCRIPT_NAME}, '/outer', 'and its SCRIPT_NAME');
}

# ---- any method, no routing table ----------------------------------------------

{
    for my $m (qw(GET POST PUT DELETE PATCH OPTIONS)) {
        my ($res) = hit(method => $m, path => '/bare/anything');
        is($res->[0], 200, "$m reaches the mount");
    }
    my ($res) = hit(method => 'POST', path => '/legacy/whatever');
    is($SEEN[0]{REQUEST_METHOD}, 'POST',
        'the method reaches the mounted app unchanged');
}

# ---- precedence ----------------------------------------------------------------

{
    # 1. a static exact route is matched before mounts are considered
    my ($res) = hit(path => '/legacy/exact');
    is(body($res), 'native exact', 'a static route beats a mount on its path');
    is(scalar @SEEN, 0, '...and the mounted app is never called');

    # 2. a mount is considered before dynamic routes
    ($res) = hit(path => '/bare/thing');
    is(body($res), 'bare:/thing', 'a mount beats a dynamic route');

    # 3. longest prefix wins, whatever the registration order
    ($res) = hit(path => '/legacy/deep/thing');
    is(body($res), 'deep:/thing',
        'the longer prefix wins even though it was registered second');

    ($res) = hit(path => '/legacy/deeper-not-really');
    is(body($res), 'legacy:/deeper-not-really',
        'a path that only looks like the longer prefix goes to the shorter');
}

{   # prefixes match on segment boundaries, not as bare strings
    my ($res) = hit(path => '/legacyfoo');
    is($res->[0], 404, '/legacyfoo is not under /legacy');
    is(scalar @SEEN, 0, 'and no mounted app saw it');
}

{
    my ($res) = hit(path => '/nowhere');
    is($res->[0], 404, 'an unmounted, unrouted path is still 404');
}

# ---- the response passes through -----------------------------------------------

{
    {
        package Passthru;
        use Punk;
        mount '/x' => sub {
            return [ 201, [ 'Content-Type', 'application/json',
                            'X-Custom', 'kept' ],
                     [ '{"a":', '1}' ] ];
        };
    }
    open my $in, '<', \'';
    my $r = Passthru->to_app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/x/y', QUERY_STRING => '',
        SERVER_NAME => 'l', SERVER_PORT => 80, HTTP_HOST => 'l',
        'psgi.url_scheme' => 'http', 'psgi.input' => $in });
    is($r->[0], 201, 'the mounted status passes through');
    my %h = @{ $r->[1] };
    is($h{'X-Custom'}, 'kept', 'its headers pass through');
    is(join('', @{ $r->[2] }), '{"a":1}',
        'and a multi-chunk body arrives whole');
}

# ---- a mount is another application, not part of this one ----------------------
# The dispatcher answers a mount and returns before the before-dispatch hooks,
# guards and after-dispatch hooks that wrap a native route. That is defensible -
# a mounted app brings its own middleware - but it means the framework's own
# protections do not extend into it, and that is worth knowing rather than
# discovering.

{
    {
        package Guarded;
        use Punk;
        session secret => 'k';
        csrf;
        hook before_dispatch => sub { $main::HOOKED++; return };
        mount '/legacy' => sub { [ 200, [], [ 'legacy' ] ] };
        post '/native'  => sub { $_[0]->text('native') };
        get  '/ping'    => sub { $_[0]->text('pong') };   # for the control
    }
    my $g = Guarded->to_app;
    my $call = sub {
        my ($path) = @_;
        open my $in, '<', \'';
        return $g->({ REQUEST_METHOD => 'POST', PATH_INFO => $path,
                      QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                      HTTP_HOST => 'l', 'psgi.url_scheme' => 'http',
                      'psgi.input' => $in });
    };

    is($call->('/native')->[0], 403,
        'a native POST with no token is refused by csrf');

    # Prove the hook fires at all before concluding anything from it not
    # firing: a control that always passed would make the next case vacuous.
    {
        open my $in, '<', \'';
        our $HOOKED = 0;
        $g->({ REQUEST_METHOD => 'GET', PATH_INFO => '/ping',
               QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
               HTTP_HOST => 'l', 'psgi.url_scheme' => 'http',
               'psgi.input' => $in });
        is($HOOKED, 1, 'before_dispatch runs for a native route');
    }

    our $HOOKED = 0;
    my $res = $call->('/legacy/write');
    is($res->[0], 200,
        'a mounted POST is NOT csrf-checked - a mount is its own application');
    is($HOOKED, 0, 'and before_dispatch hooks do not run for it either');
}

# ---- what does still apply -----------------------------------------------------
# CORS is added in pc_app_cb, outside punk_serve, so it reaches a mounted
# response even though the hooks do not.

{
    {
        package Corsed;
        use Punk;
        cors origins => [ 'https://app.example.com' ];
        mount '/legacy' => sub { [ 200, [], [ 'legacy' ] ] };
    }
    open my $in, '<', \'';
    my $r = Corsed->to_app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/legacy/x', QUERY_STRING => '',
        SERVER_NAME => 'l', SERVER_PORT => 80, HTTP_HOST => 'l',
        'psgi.url_scheme' => 'http', 'psgi.input' => $in,
        HTTP_ORIGIN => 'https://app.example.com' });
    my %h = @{ $r->[1] };
    is($h{'Access-Control-Allow-Origin'}, 'https://app.example.com',
        'CORS reaches a mounted response, being outside the dispatcher');
}

# ---- registration errors -------------------------------------------------------

{
    my $err = '';
    eval {
        package BadMount;
        use Punk;
        mount '/x' => 'not a coderef';
        BadMount->to_app;
    } or $err = $@;
    like($err, qr/needs a PSGI coderef/, 'mounting a non-coderef croaks');
}

{   # a prefix with a trailing slash is normalised, so it still matches
    {
        package Slashed;
        use Punk;
        mount '/trail/' => sub { [ 200, [], [ 'trailed:' . $_[0]{PATH_INFO} ] ] };
    }
    open my $in, '<', \'';
    my $r = Slashed->to_app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/trail/x', QUERY_STRING => '',
        SERVER_NAME => 'l', SERVER_PORT => 80, HTTP_HOST => 'l',
        'psgi.url_scheme' => 'http', 'psgi.input' => $in });
    is($r->[0], 200, 'a prefix written with a trailing slash still matches');
    is(join('', @{ $r->[2] }), 'trailed:/x', 'and strips to the same remainder');
}

done_testing();

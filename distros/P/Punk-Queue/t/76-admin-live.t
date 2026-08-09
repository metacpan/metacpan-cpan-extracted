#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# the inline app packages `use Punk` at compile time, so this guard
# must run during compilation too - a runtime skip_all would be too late
BEGIN {
    unless (eval { require Punk; 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'Punk required');
    }
}
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";

# The entity envelope: the shape app.js's bridge feeds into
# Funky.Pages.handleDataChange. Asserted at the source, because it is a
# wire contract between our server push and our own bridge.
{
    require Punk::Plugin::Queue;
    my $env = Punk::Plugin::Queue::_entity_envelope(job => update => 42);
    is_deeply($env, { type => 'entity_change', entity => 'job',
                      action => 'update', id => 42 },
              'the envelope has the documented shape');
}

# live without the detach path: warn at register, stay on polling - a ws
# route registered anyway would croak the whole app at to_app.
{
    local $ENV{PUNK_NO_HM_ABI} = 1;
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned .= $_[0] };

    package NoHmLive;
    use Punk;
    plugin 'Queue' => {
        dsn   => $DSN,
        admin => { prefix => '/q', guard => sub { return }, live => 1 },
    };
    my $app = eval { NoHmLive->to_app };
    ::ok($app, 'to_app survives live without Hyperman') or ::diag $@;
    ::like($warned, qr/staying on polling/, 'and warned at register');

    my $st = Punk::Plugin::Queue->state_for('NoHmLive');
    ::ok(!$st->{live}, 'live mode is off');
    my @ws = @{ NoHmLive->punk_app->{ws_routes} || [] };
    ::is(scalar @ws, 0, 'no ws route was registered');
}

# The client half of the same contract. Funky.WebSocket.connect() takes no
# arguments - it reads CONFIG.url, whose default is /ws/realtime, a route
# this app does not have. A URL passed to connect() is silently ignored and
# every attempt 404s with a backoff, which is exactly as quiet as it sounds.
{
    package WsUrlApp;
    use Punk;
    plugin 'Queue' => {
        dsn   => $DSN,
        admin => { prefix => '/q', guard => sub { return } },
    };
    my $app = WsUrlApp->to_app;
    my $body = '';
    open my $in, '<', \$body or die $!;
    my $js = $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/q/assets/app.js',
        QUERY_STRING => '', CONTENT_TYPE => '', CONTENT_LENGTH => 0,
        'psgi.input' => $in,
    })->[2][0];

    ::like($js, qr/Funky\.WebSocket\.init\(\{[^}]*\burl:/s,
           'app.js configures the websocket URL through init');
    ::like($js, qr/Funky\.WebSocket\.connect\(\s*\)/,
           '...and calls connect with no arguments, as Funky defines it');
    ::like($js, qr{PQ\.prefix \+ '/ws'},
           '...pointing at the admin prefix, not Funky /ws/realtime default');
}

SKIP: {
    skip 'Hyperman required for the live half', 6
        unless eval { require Punk::WebSocket; 1 }
            && Punk::WebSocket::_hm_available();

    my $f2 = queue_file();
    package LiveApp;
    use Punk;
    plugin 'Queue' => {
        dsn   => "dbi:SQLite:dbname=$f2",
        admin => {
            prefix => '/q',
            guard  => sub {
                my ($c) = @_;
                return $c->text('nope', 403)
                    unless ($c->req->header('x-admin') // '') eq 'yes';
                return;
            },
            live => 1,
        },
    };
    my $app = LiveApp->to_app;
    ::ok($app, 'to_app compiles with live on');

    my $st = Punk::Plugin::Queue->state_for('LiveApp');
    ::ok($st->{live}, 'live mode armed');
    my @ws = @{ LiveApp->punk_app->{ws_routes} || [] };
    ::is(scalar @ws, 1, 'the ws route registered');
    ::is($ws[0]{path}, '/q/ws', 'under the admin prefix');

    # the guard applies to the ws route: guards run BEFORE the upgrade
    # (punk_serve runs the chain, then dispatches the handshake), so an
    # unauthenticated GET to the ws path is rejected as plain HTTP
    my $body = '';
    open my $in, '<', \$body or die $!;
    my $res = $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/q/ws', QUERY_STRING => '',
        CONTENT_TYPE => '', CONTENT_LENGTH => 0, 'psgi.input' => $in,
    });
    ::is($res->[0], 403, 'the scope guard rejects the ws route pre-upgrade');

    # the page shell flips the live flag for app.js
    open my $in2, '<', \$body or die $!;
    $res = $app->({
        REQUEST_METHOD => 'GET', PATH_INFO => '/q', QUERY_STRING => '',
        CONTENT_TYPE => '', CONTENT_LENGTH => 0, 'psgi.input' => $in2,
        HTTP_X_ADMIN => 'yes',
    });
    ::like($res->[2][0], qr/live:\s*true/, 'the shell tells app.js live is on');
}

done_testing();

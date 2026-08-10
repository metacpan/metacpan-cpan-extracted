#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PQTest;

# The phase gate: the mount CSRF hole Punk's own t/35-mount.t documents -
# a mounted POST bypasses guards, CSRF and hooks - must not exist here.
# The admin routes are native routes under a guarded scope, and this test
# is the executable proof.

# the inline app packages `use Punk` at compile time, so this guard
# must run during compilation too - a runtime skip_all would be too late
BEGIN {
    # The VERSION check is the load-bearing half. install_kw arrived in
    # Punk 0.04 and is how the queue/task/cron keywords reach an app
    # class; against an older Punk this file compiles far enough to call
    # it and then dies mid-BEGIN, which a smoker reports as a FAIL of
    # this dist rather than as the missing dependency it is. Punk is a
    # recommends, not a requires - the queue works standalone - so an
    # old one is a normal thing to meet.
    unless (eval { require Punk; Punk->VERSION('0.04'); 1 }) {
        require Test::More;
        Test::More::plan(skip_all => 'Punk 0.04 required for the plugin');
    }
}
plan skip_all => 'DBI and DBD::SQLite required' unless has_dbd();

my $file = queue_file();
my $DSN = "dbi:SQLite:dbname=$file";

my $before_ran = 0;

{
    package SecApp;
    use Punk;

    session secret => 'test-secret-key';
    csrf;

    hook before_dispatch => sub { $before_ran++; return };

    plugin 'Queue' => {
        dsn   => $DSN,
        admin => {
            prefix => '/queue',
            guard  => sub {
                my ($c) = @_;
                return $c->text('nope', 403)
                    unless ($c->req->header('x-admin') // '') eq 'yes';
                return;
            },
        },
    };
}

my $app = SecApp->to_app;
ok($app, 'the app compiled');

require File::Raw::JSON;

# a cookie-jar hit, following Punk's own t/28-csrf.t pattern
my %jar;
sub hit_sec {
    my (%o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body or die $!;
    my $cookies = join '; ', map { "$_=$jar{$_}" } sort keys %jar;
    my $res = $app->({
        REQUEST_METHOD => $o{method} // 'GET',
        PATH_INFO      => $o{path}   // '/',
        QUERY_STRING   => $o{query}  // '',
        CONTENT_TYPE   => $o{type} // ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        ($cookies ? (HTTP_COOKIE => $cookies) : ()),
        %{ $o{env} // {} },
    });
    my @h = @{ $res->[1] };
    while (my ($k, $v) = splice @h, 0, 2) {
        next unless lc $k eq 'set-cookie';
        $jar{$1} = $2 if $v =~ /\A([^=]+)=([^;]*)/;
    }
    return $res;
}

# ---- native, not mounted ----------------------------------------------------

{
    my $registrar = SecApp->punk_app;
    my @admin = grep { $_->{path} =~ m{^/queue} }
                @{ $registrar->{router}->records };
    ok(@admin >= 15, 'admin routes are in the NATIVE router records ('
                    . scalar(@admin) . ' of them)');
    is(scalar @{ $registrar->{mounts} || [] }, 0,
       'and nothing sits in the mounts slot');
    my ($post) = grep { $_->{method} eq 'POST'
                     && $_->{path} eq '/queue/api/jobs/bulk' } @admin;
    ok($post, 'the bulk endpoint is a native POST route');
    ok(scalar @{ $post->{guards} || [] } >= 1,
       'and carries the scope guard');
}

# ---- the guard runs and rejects ---------------------------------------------

{
    my $res = hit_sec(path => '/queue/api/stats');
    is($res->[0], 403, 'the guard rejects an unauthenticated GET');

    $res = hit_sec(path => '/queue/api/stats',
                   env => { HTTP_X_ADMIN => 'yes' });
    is($res->[0], 200, 'and admits the authenticated one');

    # before_dispatch fires for admin routes (a mount would skip it)
    my $seen = $before_ran;
    hit_sec(path => '/queue/api/stats', env => { HTTP_X_ADMIN => 'yes' });
    ok($before_ran > $seen, 'before_dispatch fires for an admin route');
}

# ---- CSRF on every admin POST -----------------------------------------------

{
    # no token at all: 403 from Punk's CSRF check
    my $res = hit_sec(method => 'POST', path => '/queue/api/jobs/bulk',
                      body => '{"action":"retry","ids":[1]}',
                      env => { HTTP_X_ADMIN => 'yes' });
    is($res->[0], 403, 'POST without a CSRF token gets 403 - the exact '
                     . 'hole t/35-mount.t documents for mounts');

    $res = hit_sec(method => 'POST', path => '/queue/api/jobs/1/retry',
                   env => { HTTP_X_ADMIN => 'yes' });
    is($res->[0], 403, 'and the same for single-job writes');

    # with the token: the double-submit round trip. A GET mints the
    # cookie; replaying it in the header passes the check.
    hit_sec(path => '/queue', env => { HTTP_X_ADMIN => 'yes' });
    my ($csrf_cookie) = grep { $_ eq 'csrf' } keys %jar;
    ok($csrf_cookie, 'a GET minted the csrf cookie');

    $res = hit_sec(method => 'POST', path => '/queue/api/jobs/bulk',
                   body => '{"action":"retry","ids":[999999]}',
                   env => { HTTP_X_ADMIN => 'yes',
                            HTTP_X_CSRF_TOKEN => $jar{csrf} });
    is($res->[0], 200, 'with the token the POST goes through');
}

# ---- the csrf bridge in the shell -------------------------------------------

{
    my $res = hit_sec(path => '/queue', env => { HTTP_X_ADMIN => 'yes' });
    my $html = $res->[2][0];
    like($html, qr/\QNAME = "csrf"\E/,
         'the layout mirrors the APP\'S csrf cookie name, not a guess');
    like($html, qr/csrf_token=/,
         'into the csrf_token cookie Funky hardcodes');
}

# ---- registering without a guard croaks -------------------------------------

{
    package NakedApp;
    use Punk;
    my $died = !eval {
        plugin 'Queue' => { dsn => $DSN, admin => {} };
        1;
    };
    ::ok($died, 'admin without a guard croaks at registration');
    ::like($@, qr/guard/, 'and says why');
}

# ...unless the escape hatch is set deliberately
{
    local $ENV{PUNK_QUEUE_ADMIN_INSECURE} = 1;
    package InsecureApp;
    use Punk;
    my $ok = eval {
        plugin 'Queue' => { dsn => $DSN, admin => {} };
        1;
    };
    ::ok($ok, 'PUNK_QUEUE_ADMIN_INSECURE means it') or ::diag $@;
}

done_testing();

#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use lib 't/lib';
use PunkTest;
use Punk::Session::Store ();

# Punk::Session::Store's SYNOPSIS, executed.
#
# Read out of the POD rather than copied, the way t/0001-synopsis.t reads
# Punk.pm's: a copy drifts, and the documentation for a security feature is the
# worst place for prose that no longer runs.
#
# Two substitutions, and only two, both because the page shows a DEPLOYMENT and
# this is a test: the cache directory becomes a temporary one, and
# secret('session_key') becomes a literal, since the secrets system fails
# closed on an unset key and that is a different test. Everything else - the
# keyword, the options, the two handlers, the method names - runs as written.

my $pm = $INC{'Punk/Session/Store.pm'}
    or plan skip_all => 'cannot locate Punk::Session::Store';

my $synopsis = do {
    open my $fh, '<', $pm or plan skip_all => "cannot read $pm: $!";
    local $/;
    my $pod = <$fh>;
    close $fh;
    $pod =~ /^=head1 SYNOPSIS\s*\n(.*?)^=head1 /ms
        or plan skip_all => 'no SYNOPSIS in Punk::Session::Store';
    $1;
};

# The verbatim block, dedented. Anything not indented is prose.
my $code = join "\n",
           map  { my $l = $_; $l =~ s/\A    //; $l }
           grep { /\A(?:    |\s*\z)/ }
           split /\n/, $synopsis;

like($code, qr/store\s+=>\s+'cache'/,
    'the SYNOPSIS still configures a store - if that stops being true the '
  . 'rest of this file is testing something else');
like($code, qr/session_rotate/, 'and still rotates at the login');
like($code, qr/session_expire/, 'and still expires at the logout');

my $dir = File::Temp::tempdir(CLEANUP => 1);
$code =~ s{'/var/cache/app'}{'$dir'}                or die 'no cache dir';
$code =~ s{secret\('session_key'\)}{'a-test-secret'} or die 'no secret call';

# What the SYNOPSIS calls but does not show, because it is the application's.
{
    package MyApp;
    sub authenticate { return { id => 7 } }
}

my $ok = eval "$code\n1";
ok($ok, 'the SYNOPSIS compiles and runs') or diag $@;

SKIP: {
    skip 'the SYNOPSIS did not compile', 6 unless $ok;

    my $app = MyApp->to_app;
    ok($app, 'and the application it describes compiles');

    my $store = MyApp->punk_app->{session}{'punk.store'};
    isa_ok($store, 'Punk::Cache', 'the store it names resolved');

    my $r = hit($app, method => 'POST', path => '/login');
    my $sc;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        $sc = $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    my ($cv) = ($sc // '') =~ /punk\.sid=([^;]+)/;
    ok(defined $cv, 'logging in the way the SYNOPSIS shows sets a cookie');
    unlike($sc, qr/user_id/,
        'carrying an id and not the session - which is the whole claim of '
      . 'the page this came from');

    is($r->[0], 302, 'and redirects, as written');

    my $out = hit($app, method => 'POST', path => '/logout',
                  env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($out->[0], 302, 'logging out redirects too');

    my %s = $store->stats;
    is($s{entries} // 0, 0,
        'and the entry is gone - the SYNOPSIS comment says "deletes the '
      . 'entry: revoked", and it does');
}

done_testing;

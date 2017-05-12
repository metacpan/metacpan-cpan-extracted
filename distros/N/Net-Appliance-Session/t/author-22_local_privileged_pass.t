#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


BEGIN {
  if ($ENV{NOT_AT_HOME}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests can only be run by the author when at home');
  }
}

use strict; use warnings FATAL => 'all';
use Test::More 0.88;

BEGIN { use_ok( 'Net::Appliance::Session') }

my $s = new_ok( 'Net::Appliance::Session' => [{
    transport => "Telnet",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    host => '172.16.20.55',
    personality => "ios",
}]);

my @out = ();

ok( $s->connect({
    username => 'Cisco',
    password => ($ENV{IOS_PASS} || 'letmein'),
    privileged_password => ($ENV{IOS_PASS} || 'letmein') . 'x',
}), 'connect with bad privileged_password' );

# should fail
eval { $s->begin_privileged };
like( $@, qr/read timed-out|timeout on timer/, 'begin priv, bad pass' );
ok( eval{$s->close;1}, 'disconnected' );

# should be OK
ok( $s->connect({
    username => 'Cisco',
    password => ($ENV{IOS_PASS} || 'letmein'),
    privileged_password => ($ENV{IOS_PASS} || 'letmein') . '',
}), 'connected ok' );

ok( $s->begin_privileged, 'begin priv, no pass' );
ok( eval{$s->close;1}, 'disconnected, backed out of privileged' );

done_testing;

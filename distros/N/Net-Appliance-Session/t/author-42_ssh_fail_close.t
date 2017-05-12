#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict; use warnings FATAL => 'all';
use Test::More 0.88;

BEGIN { use_ok( 'Net::Appliance::Session') }

my $s = new_ok( 'Net::Appliance::Session' => [{
    transport => "SSH",
    ($^O eq 'MSWin32' ?
        (app => "$ENV{HOMEPATH}\\Desktop\\plink.exe") : () ),
    host => "bogus.example.com",
    personality => "cisco",
}]);

# should fail
eval { $s->connect };
like( $@, qr/Could not resolve hostname/, 'Unknown Host' );

ok( eval{$s->close;1}, 'disconnected without pathological behaviour' );

done_testing;

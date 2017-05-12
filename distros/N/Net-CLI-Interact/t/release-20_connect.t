#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict; use warnings FATAL => 'all';
use Test::More 0.88;

use Net::CLI::Interact;

my $s = Net::CLI::Interact->new({
    transport => 'Loopback',
});

ok($s->transport->init);

done_testing;

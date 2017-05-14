#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::UPS;
use Test::Net::UPS::Factory;

my $ups = Test::Net::UPS::Factory::from_config;

Test::Net::UPS::test_it($ups);

done_testing();

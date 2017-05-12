#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::DHL;
use Test::Net::Async::Webservice::DHL::Factory;

my ($dhl,$ua) = Test::Net::Async::Webservice::DHL::Factory::without_network;

$ua->prepare_test_from_file('t/data/address');
$ua->prepare_test_from_file('t/data/address-productcode');
$ua->prepare_test_from_file('t/data/address-bad');
$ua->prepare_test_from_file('t/data/route-request');
$ua->prepare_test_from_file('t/data/route-request-bad');

Test::Net::Async::Webservice::DHL::test_it($dhl);

done_testing();

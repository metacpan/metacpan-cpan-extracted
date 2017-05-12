#!perl -T
use strict;

use Test::More tests => 4;

use Net::LimeLight::Purge;
use Net::LimeLight::Purge::Request;

my $purge = Net::LimeLight::Purge->new(
    username => 'weee',
    password => 'random'
);
isa_ok($purge, 'Net::LimeLight::Purge');

my $ret = $purge->create_purge_request;
ok(!defined($ret), 'empty request does nothing');

my $ret2 = $purge->create_purge_request({});
ok(!defined($ret2), 'wrong type requests do nothing');

my $ret3 = $purge->create_purge_request([]);
ok(!defined($ret3), 'no requests does nothing');


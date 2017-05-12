#!perl -T
use strict;

use Test::More tests => 2;

use Net::LimeLight::Purge;
use Net::LimeLight::Purge::Request;

my $purge = Net::LimeLight::Purge->new(
    username => 'weee',
    password => 'random'
);
isa_ok($purge, 'Net::LimeLight::Purge');

my $req = Net::LimeLight::Purge::Request->new(
    shortname => 'testing',
    url => 'http://cdn.example.com/atchoo.jpeg'
);
isa_ok($req, 'Net::LimeLight::Purge::Request');


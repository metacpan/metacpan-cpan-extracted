#!perl

use strict;
use warnings;

use Test::More no_plan => 1;
use Test::Group;
use Test::Exception;

use_ok('Net::Squid::Purge');
use_ok('Net::Squid::Purge::HTTP');
use_ok('Net::Squid::Purge::Multicast');
use_ok('Net::Squid::Purge::UDP');

test 'http' => sub {
    my $pu = Net::Squid::Purge->new( type => 'HTTP' );
    ok($pu, 'Net::Squid::Purge object created');
    isa_ok($pu, 'Net::Squid::Purge::HTTP');
};

test 'multicast' => sub {
    my $pu = Net::Squid::Purge->new( type => 'Multicast');
    ok($pu, 'Net::Squid::Purge object created');
    isa_ok($pu, 'Net::Squid::Purge::Multicast');
};

test 'udp' => sub {
    my $pu = Net::Squid::Purge->new( type => 'UDP');
    ok($pu, 'Net::Squid::Purge object created');
    isa_ok($pu, 'Net::Squid::Purge::UDP');
};

#!/usr/bin/perl -T
use strict;
use Test::More;

BEGIN {
    use Socket;
    my $proto = getprotobyname('icmp');

    if(socket(S, PF_INET, SOCK_RAW, $proto)) {
        plan tests => 5
    } else {
        plan skip_all => "must be run as root"
    }
}

use Net::P0f;

my @interfaces = ();
my $interface = Net::P0f->lookupdev;
my %ifaces = ();

ok( @interfaces, undef ); #01

# calling as a class method
@interfaces = Net::P0f->findalldevs;
ok( scalar @interfaces   ); #02
@ifaces{ @interfaces } = (1)x@interfaces;
ok( $ifaces{$interface}  ); #03

# calling as an object method
my $obj = new Net::P0f interface => $interface;
@interfaces = undef;
@interfaces = $obj->lookupdev;
ok( scalar @interfaces   ); #04
@ifaces{ @interfaces } = (1)x@interfaces;
ok( $ifaces{$interface}  ); #05

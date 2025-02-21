#!/usr/bin/perl
# $Id: 34-NSEC3-flags.t 2003 2025-01-21 12:06:06Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Net::DNS::RR::NSEC3
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 3;


my $rr = Net::DNS::RR->new( type => 'NSEC3' );


my $optout = $rr->optout(0);
ok( !$optout, 'Boolean optout flag cleared' );

$rr->optout( !$optout );
ok( $rr->optout, 'Boolean optout flag toggled' );

$rr->optout($optout);
ok( !$optout, 'Boolean optout flag restored' );


exit;

__END__



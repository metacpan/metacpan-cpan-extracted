#!/usr/bin/perl
# $Id: 34-NSEC3-flags.t 1856 2021-12-02 14:36:25Z willem $	-*-perl-*-
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


my $optout = $rr->optout;
ok( !$optout, 'Boolean optout flag has default value' );

$rr->optout( !$optout );
ok( $rr->optout, 'Boolean optout flag toggled' );

$rr->optout($optout);
ok( !$optout, 'Boolean optout flag restored' );


exit;

__END__



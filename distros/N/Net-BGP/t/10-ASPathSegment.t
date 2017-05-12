#!/usr/bin/perl -wT

use strict;

use Test::More tests => 5;

# Use
use_ok('Net::BGP::ASPath');

foreach my $obj (qw (
	Net::BGP::ASPath::AS_SEQUENCE
	Net::BGP::ASPath::AS_SET
	Net::BGP::ASPath::AS_CONFED_SEQUENCE
	Net::BGP::ASPath::AS_CONFED_SET
	))
 {
  my $s = $obj->new([1,2,3]);
  ok(ref $s eq $obj,"Construction of '$obj'");
 };

__END__

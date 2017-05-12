#!/usr/bin/perl

use Test::More tests => 14;

#use diagnostics;
BEGIN { use_ok('Net::Interface',qw(ipV6compress :lower)); }
my $loaded = 1;
END { print "not ok 1\n" unless $loaded; }

my @hex = qw(
	0:0:0:0:f:0:0:0			::f:0:0:0
	0:0:0:f:0:0:0:0			0:0:0:f::
	0:0:0:f:0:0:0:f			::f:0:0:0:f
	ab00:ffff:0:f::			ab00:ffff:0:f::
	::				::
	120:00:345::789			120:0:345::789
	0:A:b:c:d:6:7:8			0:a:b:c:d:6:7:8
	9:a:B:c:d:6:7:0			9:a:b:c:d:6:7:0
	0:0:0:0:5::8			::5:0:0:8
	1::4:0:0:0:8			1:0:0:4::8
	1:000f:a:b:00c:d00:0e00:9	1:f:a:b:c:d00:e00:9
	1:0::0:1			1::1
	1::127.0.0.1			1::7f00:1
);

for(my $i=0; $i<@hex; $i+=2) {
  my $got = ipV6compress($hex[$i]);
  ok ($got eq $hex[$i+1],"$got eq $hex[$i+1]");
}

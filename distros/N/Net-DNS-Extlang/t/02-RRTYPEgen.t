#!/usr/bin/perl
#
use strict;
use warnings;
use Test::More;
use IO::File;

local $ENV{PATH} = 'blib/script';

plan skip_all => 'RRTYPEgen not executable'
		unless eval 'new IO::File("RRTYPEgen |")';

plan tests => 7;


my $spec = q(RRTYPE=1 "XA:4097 a host address" "A:addr IPv4 address");

my $handle = new IO::File("RRTYPEgen $spec |");

for ( join '', <$handle> ) {
	ok( /package Net::DNS::RR::XA;/,       'generated package' );
	ok( /package Net::DNS::RR::TYPE4097;/, 'has number package' );
	ok( /sub _decode_rdata/,	       'has decode routine' );
	ok( /sub _encode_rdata/,	       'has encode routine' );
	ok( /sub _format_rdata/,	       'has format routine' );
	ok( /sub _parse_rdata/,		       'has parse routine' );
	ok( /sub addr/,			       'has addr routine' );
}

exit;


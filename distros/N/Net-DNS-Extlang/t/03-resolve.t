#!/usr/bin/perl
#
use strict;
use warnings;
use Test::More;
use Net::DNS;

use Net::DNS::Extlang;

my $extobj = new Net::DNS::Extlang();
my $domain = $extobj->domain || 'services.net.';

plan skip_all => "DNS domain RRTYPE.$domain not resolvable"
		unless eval "Net::DNS::rr('1.RRTYPE.$domain', 'TXT')";

plan tests => 18;

for my $arg ( 'SOA', 6, 2 ) {
SKIP: for ( $extobj->compile($arg) ) {
		skip( "\$extobj->compile($arg) failed", 6 ) unless length $_;

		ok( /package Net::DNS::RR::.*$arg;/, "RR type $arg package" );
		ok( /package Net::DNS::RR::TYPE/,    'has number package' );
		ok( /sub _decode_rdata/,	     'has decode routine' );
		ok( /sub _encode_rdata/,	     'has encode routine' );
		ok( /sub _format_rdata/,	     'has format routine' );
		ok( /sub _parse_rdata/,		     'has parse routine' );
	}
}


exit;


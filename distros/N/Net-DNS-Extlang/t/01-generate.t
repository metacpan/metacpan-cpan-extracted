#!/usr/bin/perl
#
use strict;
use warnings;
use Test::More tests => 343;

use_ok('Net::DNS::Extlang');


my $extobj = new Net::DNS::Extlang( file => 't/rrtypes.txt' );

my $hashref = $extobj->{rrnames};

foreach my $name ( sort keys %$hashref ) {
	for ( $extobj->compile($name) ) {
		my ( $package, $type ) = ( $1, $2) if /package (Net::DNS::RR::(.+))\;/;

		ok( eval($_), "compile package $package ($name)" ) || diag $@;

		my $object = bless {}, $package;		# pseudo-object
		ok( defined( eval { $object->_defaults; 1; } ), "_defaults" );

		ok( $object->can('_parse_rdata'),  "_parse-rdata" );	# code same as _defaults

		my $string = eval { [$object->_format_rdata()] };
		ok( defined($string), "_format_rdata" );

		my $rdata = eval { $object->_encode_rdata(0) || '' };
		ok( defined($rdata), "_encode_rdata" );

		$object->{rdlength} = length( $rdata || '' );
		ok( defined( eval { $object->_decode_rdata(\$rdata,0); 1} ), "_decode_rdata" );
	}
}


exit;


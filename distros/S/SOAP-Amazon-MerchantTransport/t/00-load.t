#!/usr/bin/perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'SOAP::Amazon::MerchantTransport' );
	use_ok( 'Carp' );
	use_ok( 'Data::Dumper' );
	use_ok( 'MIME::Entity' );
	use_ok( 'SOAP::Lite' );
}

diag( "Testing SOAP::Amazon::MerchantTransport $SOAP::Amazon::MerchantTransport::VERSION, Perl $], $^X" );

#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib "$Bin";
use authorizationcodegrant_tests;

use_ok( 'Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant' );

my $Grant;

foreach my $with_callbacks ( 0,1 ) {

	isa_ok(
		$Grant = Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant->new(
			clients  => authorizationcodegrant_tests::clients(),

			# am passing in a reference to the modules subs to ensure we hit
			# the code paths to call callbacks
			( $with_callbacks ? (
				authorizationcodegrant_tests::callbacks( $Grant )
			) : () ),


		),
		'Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant'
	);

	authorizationcodegrant_tests::run_tests( $Grant,{ no_jwt => 1 } );
}

done_testing();

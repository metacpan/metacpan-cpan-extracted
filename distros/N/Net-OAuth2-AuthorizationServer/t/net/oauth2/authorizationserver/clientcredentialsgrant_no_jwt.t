#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib "$Bin";
use clientcredentialsgrant_tests;

use_ok( 'Net::OAuth2::AuthorizationServer::ClientCredentialsGrant' );

my $Grant;

foreach my $with_callbacks ( 0,1 ) {

	isa_ok(
		$Grant = Net::OAuth2::AuthorizationServer::ClientCredentialsGrant->new(
			clients    => clientcredentialsgrant_tests::clients(),

			# am passing in a reference to the modules subs to ensure we hit
			# the code paths to call callbacks
			( $with_callbacks ? (
				clientcredentialsgrant_tests::callbacks( $Grant )
			) : () ), 


		),
		'Net::OAuth2::AuthorizationServer::ClientCredentialsGrant'
	);

	clientcredentialsgrant_tests::run_tests( $Grant );
}

done_testing();

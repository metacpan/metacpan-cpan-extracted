#!perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;

use FindBin qw/ $Bin /;
use lib "$Bin";
use passwordgrant_tests;

use_ok( 'Net::OAuth2::AuthorizationServer::PasswordGrant' );

my $Grant;

foreach my $with_callbacks ( 0,1 ) {

	isa_ok(
		$Grant = Net::OAuth2::AuthorizationServer::PasswordGrant->new(
			clients  => passwordgrant_tests::clients(),
			users    => passwordgrant_tests::users(),

			# am passing in a reference to the modules subs to ensure we hit
			# the code paths to call callbacks
			( $with_callbacks ? (
				passwordgrant_tests::callbacks( $Grant )
			) : () ),


		),
		'Net::OAuth2::AuthorizationServer::PasswordGrant'
	);

	passwordgrant_tests::run_tests( $Grant );
}

done_testing();

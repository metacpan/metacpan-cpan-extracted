#!perl

use strict;
use warnings;

package Test::Defaults;

use Moo;
with 'Net::OAuth2::AuthorizationServer::Defaults';

use Test::Most;
use Test::Exception;

isa_ok( my $t = Test::Defaults->new,'Test::Defaults' );

throws_ok(
	sub { $t->_uses_auth_codes },
	qr/You must override _uses_auth_codes/,
    '_uses_auth_codes must be overriden in subclass',
);

ok( ! $t->_has_clients,'! _has_clients' );

my ( $res,$error ) = $t->verify_token_and_scope( auth_header => "Foo Bar" );
is( $error,'invalid_request','verify_token_and_scope with bad auth_header' );

done_testing();

#!perl

use strict;
use warnings;

use Test::Most;

use_ok( 'Net::OAuth2::AuthorizationServer' );

isa_ok(
    my $Server = Net::OAuth2::AuthorizationServer->new(
    ),
    'Net::OAuth2::AuthorizationServer'
);

can_ok(
    $Server,
    qw/
		auth_code_grant
		password_grant
	/
);

isa_ok(
    my $Grant = $Server->auth_code_grant(
		clients => { foo => {} },
    ),
    'Net::OAuth2::AuthorizationServer::AuthorizationCodeGrant'
);

isa_ok(
    $Grant = $Server->password_grant(
		clients => { foo => {} },
    ),
    'Net::OAuth2::AuthorizationServer::PasswordGrant'
);

isa_ok(
    $Grant = $Server->implicit_grant(
		clients => { foo => {} },
    ),
    'Net::OAuth2::AuthorizationServer::ImplicitGrant'
);

isa_ok(
    $Grant = $Server->client_credentials_grant(
		clients => { foo => {} },
    ),
    'Net::OAuth2::AuthorizationServer::ClientCredentialsGrant'
);

done_testing();

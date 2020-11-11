use strict; use warnings;
use Test::More tests => ( 3 + 256 + 3 + 256 ) * 2 + 2;
use Net::OAuth2Server::PKCE;
use Net::OAuth2Server::Request::Authorization;
use Net::OAuth2Server::Request::Token::AuthorizationCode;
use Role::Tiny;
use Data::Dumper;

Role::Tiny->apply_roles_to_package( glob 'Net::OAuth2Server::Request::Authorization{,::Role::PKCE}' );
Role::Tiny->apply_roles_to_package( glob 'Net::OAuth2Server::Request::Token::AuthorizationCode{,::Role::PKCE}' );

my ( $v, $ch ) = (
	'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
	'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
);

my %valid = map +( $_, 1 ), 45, 48 .. 57, 95, 65 .. 90, 97 .. 122;
for (
	[ 'shorter value', 'a' x 42, 'bad code_challenge length: 42 (must be 43)' ],
	[ 'correct value', 'a' x 43 ],
	[ 'longer value',  'a' x 44, 'bad code_challenge length: 44 (must be 43)' ],
	( map [ ( sprintf 'character 0x%02X', $_ ), ( sprintf '%%%02X%042d', $_, 0 ), $valid{ $_ } ? () : ( sprintf 'bad character in code_challenge: 0x%02X at position 0', $_ ) ], 0 .. 255 ),
) {
	my ( $desc, $v, $error ) = @$_;
	my $req = Net::OAuth2Server::Request::Authorization->from( GET => 'response_type=code;code_challenge_method=S256;code_challenge=' . $v );
	my @ret = $req->get_pkce_challenge;
	if ( defined $error ) {
		is 0+@ret, 0, "challenge with $desc: no values returned";
		is_deeply $req->error ? $req->error->param : undef, { qw( error invalid_request error_description ), $error }, '... with correct error';
	}
	else {
		( my $dec = $v ) =~ s!%(..)! chr hex $1 !ge;
		is_deeply \@ret, [ $dec, 'S256' ], "challenge with $desc: values returned";
		ok !$req->error, '... and no error';
		diag +Data::Dumper->Dump( [ $req->error->param ], [ 'req->error->param' ] ) if $req->error;
	}
}

$valid{ $_ } = 1 for 46, 126;
for (
	[ 'shorter value', 'a' x 42, 'bad code_challenge length: 42 (must be 43 (min) to 128 (max))' ],
	[ 'correct value', 'a' x 60 ],
	[ 'longer value',  'a' x 129, 'bad code_challenge length: 129 (must be 43 (min) to 128 (max))' ],
	( map [ ( sprintf 'character 0x%02X', $_ ), ( sprintf '%%%02X%042d', $_, 0 ), $valid{ $_ } ? () : ( sprintf 'bad character in code_challenge: 0x%02X at position 0', $_ ) ], 0 .. 255 ),
) {
	my ( $desc, $v, $error ) = @$_;
	my $req = Net::OAuth2Server::Request::Token::AuthorizationCode->from(
		POST => '',
		{ 'Content-Type', 'application/x-www-form-urlencoded' },
		'code=1;client_id=1;redirect_uri=1;code_verifier=' . $v
	);
	my @ret = $req->get_pkce_challenge( 'S256' );
	if ( defined $error ) {
		is 0+@ret, 0, "verifier with $desc: no values returned";
		is_deeply $req->error ? $req->error->param : undef, { qw( error invalid_request error_description ), $error }, '... with correct error';
	}
	else {
		is 0+@ret, 1, "verifier with $desc: values returned";
		ok !$req->error, '... and no error';
		diag +Data::Dumper->Dump( [ $req->error->param ], [ 'req->error->param' ] ) if $req->error;
	}
}

is +( Net::OAuth2Server::Request::Token::AuthorizationCode->from( GET => 'code_verifier=' . $v )->get_pkce_challenge( 'plain' ) )[0], $v, 'code_challenge_method plain';
is +( Net::OAuth2Server::Request::Token::AuthorizationCode->from( GET => 'code_verifier=' . $v )->get_pkce_challenge( 'S256' ) )[0], $ch, 'code_challenge_method S256 (example from RFC 7636 Appendix B)';

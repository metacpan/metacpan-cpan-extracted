#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Crypt::PK::RSA;
use MIME::Base64 qw( encode_base64url );
use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
$fake->add_realm('main');
my $oidc   = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', http => $http )->oidc;
my $issuer = $fake->base.'/realms/main';

sub claims { { iss => $issuer, sub => 'u-1', aud => 'my-api', exp => time + 300, iat => time, @_ } }

subtest 'discovery' => sub {
  is( $oidc->token_endpoint_f->get, $issuer.'/protocol/openid-connect/token', 'token_endpoint' );
  is( $oidc->device_endpoint_f->get, $issuer.'/protocol/openid-connect/auth/device', 'device_endpoint' );
  my $count = grep { $_->uri =~ /well-known/ } @{ $fake->requests };
  $oidc->userinfo_endpoint_f->get;
  is( scalar( grep { $_->uri =~ /well-known/ } @{ $fake->requests } ), $count, 'fetched once' );
  ok( !eval { $oidc->endpoint_f('nope_endpoint')->get; 1 }, 'a missing endpoint croaks' );
  like( "$@", qr/has no nope_endpoint/, 'and names it' );
};

subtest 'verify_token' => sub {
  my $claims = $oidc->verify_token_f( $fake->sign( claims() ), audience => 'my-api' )->get;
  is( $claims->{sub}, 'u-1', 'a good token' );
  ok( $oidc->verify_token_f( $fake->sign( claims() ) )->get, 'audience is only checked when asked' );
  my %bad = (
    'wrong issuer'   => $fake->sign( claims( iss => 'https://evil/realms/main' ) ),
    'expired'        => $fake->sign( claims( exp => time - 10 ) ),
    'wrong audience' => $fake->sign( claims( aud => 'other' ) ),
    'foreign key'    => do { my $k = Crypt::PK::RSA->new; $k->generate_key( 256, 65537 ); $fake->sign( claims(), key => $k ) },
    'HMAC'           => $fake->sign( claims(), alg => 'HS256', key => 'secret' ),
    'not a JWT'      => 'abc.def'
  );
  for my $case ( sort keys %bad ) {
    ok( !eval { $oidc->verify_token_f( $bad{$case}, audience => 'my-api' )->get; 1 }, $case.' is rejected' );
    isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
  }
  my ( $none ) = map { join '.', $_, encode_base64url('{"iss":"'.$issuer.'","sub":"x","exp":'.( time + 60 ).'}'), '' } encode_base64url('{"alg":"none"}');
  ok( !eval { $oidc->verify_token_f($none)->get; 1 }, 'alg none is rejected' );
  ok( !eval { $oidc->verify_token_f('')->get; 1 }, 'an empty token' );
};

subtest 'key rotation' => sub {
  my $clock   = time;
  my $rotated = Net::Async::Keycloak::OIDC->new( issuer => $issuer, http => $http, now => sub { $clock } );
  my $fetches = sub { scalar grep { $_->uri =~ /certs/ } @{ $fake->requests } };
  $rotated->jwks_f->get;
  my $start = $fetches->();

  for my $junk ( $fake->sign( claims( iss => 'https://evil' ) ), $fake->sign( claims( exp => time - 1 ) ), 'abc.def' ) {
    ok( !eval { $rotated->verify_token_f($junk)->get; 1 }, 'a bad token is rejected' );
  }
  is( $fetches->(), $start, 'without fetching the keys again' );

  $fake->rotate_key;
  ok( !eval { $rotated->verify_token_f( $fake->sign( claims() ) )->get; 1 }, 'a new key right after the last fetch is not looked up yet' );
  is( $fetches->(), $start, 'jwks_min_age holds the fetch back' );
  $clock += 60;
  ok( $rotated->verify_token_f( $fake->sign( claims() ) )->get, 'a minute later the token with the new key verifies' );
  is( $fetches->(), $start + 1, 'after one fetch' );
  ok( !eval { $rotated->verify_token_f( $fake->sign( claims(), kid => 'unknown' ) )->get; 1 }, 'an unknown kid right after' );
  is( $fetches->(), $start + 1, 'does not fetch again' );
};

subtest 'typ' => sub {
  # a client of its own: the shared one still holds the keys from before the rotation
  my $oidc = Net::Async::Keycloak::OIDC->new( issuer => $issuer, http => $http );
  ok( $oidc->verify_token_f( $fake->sign( claims( typ => 'Bearer' ) ), type => 'Bearer' )->get, 'an access token where one is expected' );
  ok( !eval { $oidc->verify_token_f( $fake->sign( claims( typ => 'ID' ) ), type => 'Bearer' )->get; 1 }, 'an ID token where an access token is expected' );
  like( "$@", qr/typ is ID, expected Bearer/, 'says why' );
  ok( !eval { $oidc->verify_token_f( $fake->sign( claims() ), type => 'Bearer' )->get; 1 }, 'no typ at all' );
  ok( $oidc->verify_token_f( $fake->sign( claims( typ => 'ID' ) ) )->get, 'without type nothing is checked' );
};

subtest 'token endpoint' => sub {
  my $tokens = $oidc->password_token_f( client_id => 'admin-cli', username => 'admin', password => 'admin', totp => '123456', scope => 'openid' )->get;
  like( $tokens->{access_token}, qr/\Aat-/, 'password_token' );
  is_deeply( { map { $_ => $fake->logins->[-1]{$_} } qw( grant_type username totp scope client_id ) },
    { grant_type => 'password', username => 'admin', totp => '123456', scope => 'openid', client_id => 'admin-cli' }, 'sends totp and scope' );
  ok( $oidc->client_credentials_token_f( client_id => 'svc', client_secret => 'secret' )->get->{access_token}, 'client_credentials_token' );
  ok( $oidc->refresh_token_f( $tokens->{refresh_token}, client_id => 'admin-cli' )->get->{access_token}, 'refresh_token' );
  ok( !eval { $oidc->password_token_f( username => 'a', password => 'b' )->get; 1 }, 'without client_id' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
};

subtest 'device flow, one step at a time' => sub {
  my $start = $oidc->device_authorization_f( client_id => 'cli', scope => 'openid' )->get;
  is( $start->{user_code}, 'ABCD-EFGH', 'device_authorization' );
  ok( !eval { $oidc->device_token_f( device_code => $start->{device_code}, client_id => 'cli' )->get; 1 }, 'a pending poll croaks' );
  is( $@->oauth_error, 'authorization_pending', 'with oauth_error authorization_pending' );
};

subtest 'userinfo, introspect, logout' => sub {
  is( $oidc->userinfo_f('user-token')->get->{preferred_username}, 'alice', 'userinfo' );
  ok( !eval { $oidc->userinfo_f('bad')->get; 1 } && $@->is_unauthorized, 'userinfo with a bad token' );
  ok( $oidc->introspect_f( 'user-token', client_id => 'api', client_secret => 's' )->get->{active}, 'introspect' );
  ok( $oidc->logout_f( refresh_token => 'r', client_id => 'cli' )->get, 'logout' );
};

done_testing;

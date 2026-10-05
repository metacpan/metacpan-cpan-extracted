#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use IO::Async::Loop;
use Scalar::Util qw( blessed );
use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
my $kc   = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', http => $http );

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

subtest 'classes and stringification' => sub {
  my $e = Net::Async::Keycloak::Error::API->new( message => 'boom', http_status => 409 );
  isa_ok( $e, 'Net::Async::Keycloak::Error' );
  is( "$e", 'boom', 'stringifies to the message' );
  ok( $e->is_conflict && !$e->is_not_found && !$e->is_unauthorized, 'predicates' );
  isa_ok( Net::Async::Keycloak::Error::Validation->new( message => 'x' ), 'Net::Async::Keycloak::Error' );
  isa_ok( Net::Async::Keycloak::Error::Network->new( message => 'x' ), 'Net::Async::Keycloak::Error' );
  my $thrown = error_of { Net::Async::Keycloak::Error::Validation->throw( message => 'thrown' ) };
  isa_ok( $thrown, 'Net::Async::Keycloak::Error::Validation', 'throw' );
};

subtest 'the three shapes Keycloak answers errors in' => sub {
  my $conflict = error_of { $kc->admin->create_realm_f->get };
  isa_ok( $conflict, 'Net::Async::Keycloak::Error::API' );
  is( $conflict->http_status, 409, 'status as a number' );
  is( $conflict->api_message, 'Realm master already exists', 'errorMessage' );
  ok( $conflict->is_conflict, 'is_conflict' );
  like( "$conflict", qr{POST http://kc.test/admin/realms failed: 409 .* - Realm master already exists}, 'message names the request' );

  my $missing = error_of { $kc->admin->get_client_f('nope')->get };
  ok( $missing->is_not_found, 'is_not_found' );
  is( $missing->api_message, 'Could not find client', 'error' );
  is( $missing->oauth_error, undef, 'an admin error is no OAuth error' );

  my $oauth = error_of { $kc->oidc->password_token_f( client_id => 'cli', username => 'x', password => 'y' )->get };
  is( $oauth->oauth_error, 'invalid_grant', 'oauth_error from the token endpoint' );
  is( $oauth->api_message, 'invalid_grant: Invalid user credentials', 'with the description' );
};

subtest 'no answer at all' => sub {
  my $loop = IO::Async::Loop->new;
  my $down = Net::Async::Keycloak->new( base_url => 'http://127.0.0.1:9', realm => 'x' );
  $loop->add($down);
  my $future = $down->oidc->discovery_f;
  $loop->await($future);
  my $error = $future->failure;
  isa_ok( $error, 'Net::Async::Keycloak::Error::Network' );
  like( "$error", qr{GET http://127.0.0.1:9/realms/x/.well-known/openid-configuration: }, 'names the request' );
};

done_testing;

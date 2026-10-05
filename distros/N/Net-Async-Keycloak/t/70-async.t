#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Future;
use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

# A Net::Async::HTTP stand-in whose answers arrive only when the test says so,
# to see what happens while requests are under way.
{
  package DeferredHTTP;
  sub new { bless { fake => $_[1], queue => [] }, $_[0] }
  sub pending { scalar @{ $_[0]{queue} } }
  sub do_request {
    my ( $self, %arg ) = @_;
    my $future = Future->new;
    push @{ $self->{queue} }, [ $future, $arg{request} ];
    return $future;
  }
  sub answer_all {
    my ( $self ) = @_;
    while ( my $next = shift @{ $self->{queue} } ) { $next->[0]->done( $self->{fake}->request( $next->[1] ) ) }
    return;
  }
}

my $fake = FakeKeycloak->new;

subtest 'callers waiting for a token share one login' => sub {
  my $http = DeferredHTTP->new($fake);
  my $auth = Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', username => 'admin', password => 'admin' );
  @{ $fake->logins } = ();
  my @waiting = map { $auth->token_f } 1 .. 3;
  is( $http->pending, 1, 'three callers, one request' );
  ok( !$waiting[0]->is_ready, 'nobody has a token yet' );
  $http->answer_all;
  ok( !grep( { !$_->is_done } @waiting ), 'all three are served' );
  my %seen = map { $_->get => 1 } @waiting;
  is( scalar keys %seen, 1, 'with the same token' );
  is( scalar @{ $fake->logins }, 1, 'from one login' );
  is( $auth->token_f->get, $waiting[0]->get, 'and the next caller gets it at once' );
  is( $http->pending, 0, 'without a request' );
};

subtest 'a failed login does not stick' => sub {
  my $http = DeferredHTTP->new($fake);
  my $auth = Net::Async::Keycloak::Auth->new( http => $http, token_endpoint => $fake->base.'/realms/master/protocol/openid-connect/token', username => 'admin', password => 'nope' );
  my $first = $auth->token_f;
  $http->answer_all;
  ok( $first->is_failed, 'the login fails' );
  my $second = $auth->token_f;
  is( $http->pending, 1, 'the next caller tries again instead of getting the old failure' );
  $http->answer_all;
};

subtest 'requests run side by side' => sub {
  my $http  = DeferredHTTP->new($fake);
  my $kc    = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', token => 'x', http => $http );
  $fake->{tokens}{x} = 1;
  my @calls = ( $kc->admin->get_realm_f, $kc->admin->list_clients_f, $kc->admin->list_users_f );
  is( $http->pending, 3, 'three requests are out at once' );
  $http->answer_all;
  ok( !grep( { !$_->is_done } @calls ), 'and all three complete' );
};

sub drain {
  my ( $http, @futures ) = @_;
  for ( 1 .. 50 ) {
    last unless grep { !$_->is_ready } @futures;
    $http->answer_all;
  }
  return;
}

subtest 'cancelling one caller leaves the shared login alone' => sub {
  my $http  = DeferredHTTP->new($fake);
  my $admin = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', http => $http )->admin;
  my $first  = $admin->get_realm_f;
  my $second = $admin->get_realm_f;
  is( $http->pending, 1, 'one login under way for both' );
  $first->cancel;
  drain( $http, $second );
  ok( $second->is_done, 'the other caller still gets its answer' );
  is( $second->get->{realm}, 'master', 'the right one' );
};

subtest 'tokens refused together cause one new login' => sub {
  my $http  = DeferredHTTP->new($fake);
  my $admin = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', username => 'admin', password => 'admin', http => $http )->admin;
  my $warm  = $admin->get_realm_f;
  drain( $http, $warm );
  $fake->forget_tokens;
  @{ $fake->logins } = ();
  my @calls = map { $admin->get_realm_f } 1 .. 3;
  drain( $http, @calls );
  ok( !grep( { !$_->is_done } @calls ), 'all three succeed after the restart' );
  is( scalar @{ $fake->logins }, 1, 'with one login, not three' );
};

subtest 'concurrent verifications share the key fetch' => sub {
  my $http = DeferredHTTP->new($fake);
  my $oidc = Net::Async::Keycloak::OIDC->new( issuer => $fake->base.'/realms/master', http => $http, jwks_min_age => 0 );
  my $count = sub { my ( $what ) = @_; scalar grep { $_->uri =~ $what } @{ $fake->requests } };
  my ( $certs, $discovery ) = ( $count->(qr/certs/), $count->(qr/well-known/) );
  my $claims = { iss => $fake->base.'/realms/master', sub => 'x', exp => time + 60 };
  my @forged = map { $oidc->verify_token_f( $fake->sign( $claims, kid => 'unknown-'.$_ ) ) } 1 .. 20;
  drain( $http, @forged );
  ok( !grep( { !$_->is_failed } @forged ), 'twenty tokens with unknown keys are rejected' );
  ok( !grep( { !$_->failure->isa('Net::Async::Keycloak::Error::Validation') } @forged ), 'with validation errors' );
  is( $count->(qr/well-known/) - $discovery, 1, 'one discovery request for all of them' );
  is( $count->(qr/certs/) - $certs, 2, 'two key fetches for all of them: the first, and one more for the unknown keys' );
};

subtest 'not in a loop' => sub {
  my $kc     = Net::Async::Keycloak->new( base_url => 'http://127.0.0.1:9', realm => 'x' );
  my $future = $kc->oidc->discovery_f;
  ok( $future->is_failed, 'a failed future, not an exception' );
  isa_ok( $future->failure, 'Net::Async::Keycloak::Error::Network' );
  like( $future->failure->message, qr/added to a loop/, 'saying what is missing' );
};

subtest 'wrong arguments fail the future' => sub {
  my $admin = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'master', token => 'x', http => FakeHTTP->new( fake => $fake ) )->admin;
  for my $future ( $admin->partial_import_f, $admin->update_execution_config_f('id') ) {
    ok( $future->is_failed, 'failed, not thrown' );
    isa_ok( $future->failure, 'Net::Async::Keycloak::Error::Validation' );
  }
};

subtest 'like WWW::Keycloak' => sub {
  my $kc = Net::Async::Keycloak->new( { base_url => $fake->base.'/', realm => 'master', http => FakeHTTP->new( fake => $fake ) } );
  is( $kc->base_url, $fake->base, 'new takes a hash reference too' );
  like( $kc->oidc->$_->get, qr{\Ahttp://kc.test/realms/master/}, $_ ) for qw( introspection_endpoint_f end_session_endpoint_f jwks_uri_f );
};

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Net::Async::HTTP;
use FakeAuthentik;
use FakeHTTP;
use Net::Async::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

subtest 'base_url' => sub {
  my $missing = error_of { Net::Async::Authentik->new };
  ok( $missing, 'base_url is required' );
  isa_ok( error_of { Net::Async::Authentik->new( base_url => '' ) }, 'Net::Async::Authentik::Error::Validation', 'an empty base_url' );
  is( Net::Async::Authentik->new( base_url => 'https://id.example.org/' )->base_url, 'https://id.example.org', 'a trailing slash is removed' );
  is( Net::Async::Authentik->new( base_url => 'https://id.example.org///' )->base_url, 'https://id.example.org', 'several of them too' );
};

subtest 'addresses' => sub {
  my $ak = Net::Async::Authentik->new( base_url => 'https://id.example.org', application => 'my-app', token => 't' );
  is( $ak->api_url, 'https://id.example.org/api/v3', 'api_url' );
  is( $ak->application_url, 'https://id.example.org/application/o/my-app', 'application_url' );
  is( $ak->issuer, 'https://id.example.org/application/o/my-app/', 'issuer' );
  is( Net::Async::Authentik->new( base_url => 'https://id.example.org', application => 'a b' )->application_url,
      'https://id.example.org/application/o/a%20b', 'the slug is URI encoded' );
};

subtest 'sub clients' => sub {
  # unlike the synchronous client, reaching for a sub client never throws:
  # the complaint comes as a failed future when a method is called
  my $without = Net::Async::Authentik->new( base_url => 'https://id.example.org' );
  isa_ok( $without->oidc, 'Net::Async::Authentik::OIDC', 'oidc without an application still exists, it' );
  isa_ok( $without->api, 'Net::Async::Authentik::API', 'and so does api without a token, it' );
  my $no_slug = error_of { $without->oidc->discovery_f->get };
  isa_ok( $no_slug, 'Net::Async::Authentik::Error::Validation', 'calling oidc without an application' );
  like( "$no_slug", qr/application slug/, 'and says so' );
  my $no_token = error_of { $without->api->me_f->get };
  isa_ok( $no_token, 'Net::Async::Authentik::Error::Validation', 'calling api without a token' );
  like( "$no_token", qr/API token/, 'and says so' );

  my $ak = Net::Async::Authentik->new( base_url => 'https://id.example.org', application => 'my-app', token => 'secret-token' );
  isa_ok( $ak->oidc, 'Net::Async::Authentik::OIDC' );
  isa_ok( $ak->api, 'Net::Async::Authentik::API' );
  is( $ak->oidc, $ak->oidc, 'the same OIDC object every time' );
  is( $ak->oidc->http, $ak->api->http, 'both share the HTTP client' );
  is( $ak->api->token, 'secret-token', 'the token reaches the API client' );
  # the notifier hands every unknown key to configure, which refuses it, so
  # trying to put a sub client in from outside is louder here than in the
  # synchronous client, where it is quietly ignored
  my $forged = error_of { Net::Async::Authentik->new( base_url => 'https://id.example.org',
    application => 'my-app', token => 't', oidc => 'forged', api => 'forged' ) };
  like( "$forged", qr/Unrecognised configuration keys/, 'a sub client cannot be set from outside' );
};

subtest 'the HTTP client' => sub {
  my $ak = Net::Async::Authentik->new( base_url => 'https://id.example.org' );
  my $http = $ak->http;
  isa_ok( $http, 'Net::Async::HTTP' );
  # authentik answers 302 where it wants a browser, and those are read
  is( $http->{max_redirects}, 0, 'it follows no redirects' );
  # a 4xx has to come back as a response, so read_response can make an error
  # with authentik's own message out of it
  ok( !$http->{fail_on_error}, 'and does not turn a 4xx into a failure of its own' );
  like( $http->{user_agent}, qr{\ANet-Async-Authentik/}, 'and says who it is' );
  # nothing about the TE connection token here: Net::Async::HTTP does not
  # announce it, so authentik answers every request (unlike LWP's default)
  ok( !grep( { lc $_ eq 'te' } keys %{ $http->{headers} || {} } ), 'it announces no TE' );

  ok( grep( { $_ == $http } $ak->children ), 'the HTTP client is a child notifier' );
  my $shared = Net::Async::HTTP->new;
  my $borrowed = Net::Async::Authentik->new( base_url => 'https://id.example.org', http => $shared );
  is( $borrowed->http, $shared, 'an injected one is used' );
  ok( !grep( { $_ == $shared } $borrowed->children ), 'and not adopted as a child' );
  is( $borrowed->api->http, $shared, 'by the API client' );
  is( $borrowed->oidc->http, $shared, 'and by the OIDC client' );
};

subtest 'for_application' => sub {
  my $fake = FakeAuthentik->new;
  my $ak   = Net::Async::Authentik->new( base_url => $fake->base, application => 'one', token => 't', http => FakeHTTP->new( fake => $fake ) );
  my $other = $ak->for_application('two');
  isa_ok( $other, 'Net::Async::Authentik' );
  is( $other->application, 'two', 'another application' );
  is( $other->base_url, $ak->base_url, 'same instance' );
  is( $other->http, $ak->http, 'same HTTP client object' );
  is( $other->token, 't', 'same token' );
  isnt( $other->oidc, $ak->oidc, 'but its own OIDC client' );

  my $anonymous = Net::Async::Authentik->new( base_url => 'https://id.example.org' )->for_application('two');
  ok( !$anonymous->has_token, 'without a token it stays without one' );
};

done_testing;

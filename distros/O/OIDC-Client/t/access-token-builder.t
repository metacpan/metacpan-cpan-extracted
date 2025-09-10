#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

use OIDC::Client::AccessToken;
use OIDC::Client::TokenResponse;

my $class = 'OIDC::Client::AccessTokenBuilder';
use_ok $class, qw( build_access_token_from_token_response
                   build_access_token_from_claims );

launch_tests();
done_testing;

sub test_build_access_token_from_token_response {
  subtest "build_access_token_from_token_response() - a maximum of information" => sub {

    # Given
    my $token_response = OIDC::Client::TokenResponse->new(
      access_token  => 'my_access_token',
      id_token      => 'my_id_token',
      refresh_token => 'my_refresh_token',
      token_type    => 'my_token_type',
      expires_in    => 3600,
      scope         => ' scope1  scope2 ',
    );
    my $test = OIDCClientTest->new();
    $test->mock_access_token_builder(time => 10000);

    # When
    my $access_token = build_access_token_from_token_response($token_response);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token         => 'my_access_token',
      refresh_token => 'my_refresh_token',
      token_type    => 'my_token_type',
      expires_at    => 13600,
      scopes        => [qw(scope1 scope2)],
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };

  subtest "build_access_token_from_token_response() - a minimum of information" => sub {

    # Given
    my $token_response = OIDC::Client::TokenResponse->new(
      access_token => 'my_access_token',
    );

    # When
    my $access_token = build_access_token_from_token_response($token_response);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token => 'my_access_token',
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };
}

sub test_build_access_token_from_claims {
  subtest "build_access_token_from_claims() - a maximun of information" => sub {

    # Given
    my $token = 'TOKEN';
    my %claims = ();

    # When
    my $access_token = build_access_token_from_claims(\%claims, $token);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token  => 'TOKEN',
      claims => {},
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };

  subtest "build_access_token_from_claims() - scope claim is 'scp' array" => sub {

    # Given
    my $token = 'TOKEN';
    my %claims = (
      exp => 1234567890,
      scp => [qw/scope/],
    );

    # When
    my $access_token = build_access_token_from_claims(\%claims, $token);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token      => 'TOKEN',
      expires_at => 1234567890,
      scopes     => [qw/scope/],
      claims => {
        exp => 1234567890,
        scp => [qw/scope/],
      },
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };

  subtest "build_access_token_from_claims() - scope claim is 'scope' string" => sub {

    # Given
    my $token = 'TOKEN';
    my %claims = (
      scope => ' scope1  scope2 scope3 ',
    );

    # When
    my $access_token = build_access_token_from_claims(\%claims, $token);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token  => 'TOKEN',
      scopes => [qw/scope1 scope2 scope3/],
      claims => {
        scope => ' scope1  scope2 scope3 ',
      },
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };

  subtest "build_access_token_from_claims() - scope claim is 'scope' array" => sub {

    # Given
    my $token = 'TOKEN';
    my %claims = (
      scope => [qw/scope1 scope2/],
    );

    # When
    my $access_token = build_access_token_from_claims(\%claims, $token);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token  => 'TOKEN',
      scopes => [qw/scope1 scope2/],
      claims => {
        scope => [qw/scope1 scope2/],
      },
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };

  subtest "build_access_token_from_claims() - scope claim is not defined" => sub {

    # Given
    my $token = 'TOKEN';
    my %claims = (
      scope => undef,
    );

    # When
    my $access_token = build_access_token_from_claims(\%claims, $token);

    # Then
    my $expected_access_token = OIDC::Client::AccessToken->new(
      token => 'TOKEN',
      claims => {
        scope => undef,
      },
    );
    cmp_deeply($access_token, $expected_access_token,
               'expected access_token object');
  };
}

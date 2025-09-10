#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client::AccessToken';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_has_scope {
  subtest "has_scope() with scopes" => sub {

    # Given
    my $access_token = $class->new(
      token  => 'my_token',
      scopes => [qw/scope11 scope12/],
    );

    # When - Then
    ok($access_token->has_scope('scope11'),
       'has scope');
    ok($access_token->has_scope('scope12'),
       'has another scope');
    ok(! $access_token->has_scope('scope1'),
       'has not scope');
  };

  subtest "has_scope() without scope" => sub {

    # Given
    my $access_token = $class->new(
      token => 'my_token',
    );

    # When - Then
    ok(! $access_token->has_scope('scope11'),
       'has not scope');
  };
}

sub test_has_expired {
  subtest "has_expired() - token has expired" => sub {

    # Given
    my $access_token = $class->new(
      token      => 'my_token',
      expires_at => 12,
    );

    # When
    my $has_expired = $access_token->has_expired();

    # Then
    ok($has_expired, 'has expired');
  };

  subtest "has_expired() - token has not expired" => sub {

    # Given
    my $access_token = $class->new(
      token      => 'my_token',
      expires_at => time + 5,
    );

    # When
    my $has_expired = $access_token->has_expired();

    # Then
    is($has_expired, '', 'has not expired');
  };

  subtest "has_expired() - no expiration time information" => sub {

    # Given
    my $access_token = $class->new(
      token => 'my_token',
    );

    # When
    my $has_expired = $access_token->has_expired();

    # Then
    is($has_expired, undef, 'returns undef');
  };

  subtest "has_expired() - including leeway, token has expired" => sub {

    # Given
    my $access_token = $class->new(
      token      => 'my_token',
      expires_at => time + 5,
    );

    # When
    my $has_expired = $access_token->has_expired(10);

    # Then
    ok($has_expired, 'has expired');
  };

  subtest "has_expired() - including leeway, token has not expired" => sub {

    # Given
    my $access_token = $class->new(
      token      => 'my_token',
      expires_at => time + 15,
    );

    # When
    my $has_expired = $access_token->has_expired(10);

    # Then
    is($has_expired, '', 'has not expired');
  };
}

sub test_to_hashref {
  subtest "to_hashref() - all attributes" => sub {

    my %data = (
      token      => 'my_token',
      token_type => 'my_token_type',
      expires_at => 1234,
      scopes     => [qw/scope1 scope2/],
      claims     => { 'c1' => 'claim1', 'c2' => 'claim2' }
    );

    # Given
    my $access_token = $class->new(%data);

    # When
    my $access_token_href = $access_token->to_hashref();

    # Then
    cmp_deeply($access_token_href, \%data,
               'expected result');
  };

  subtest "to_hashref() - only attributes having defined values" => sub {

    my %data = (
      token      => 'my_token',
      token_type => undef,
    );

    # Given
    my $access_token = $class->new(%data);

    # When
    my $access_token_href = $access_token->to_hashref();

    # Then
    my %expected_result = (
      token => 'my_token',
    );
    cmp_deeply($access_token_href, \%expected_result,
               'expected result');
  };
}

#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

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

sub test_compute_at_hash {
  subtest "compute_at_hash() using sha256" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $alg = 'HS256';

    # When
    my $at_hash = $access_token->compute_at_hash($alg);

    # Then
    cmp_deeply($at_hash, 'nDwWvpw0im9HE0QZkgwo7A',
               'expected at_hash');
  };

  subtest "compute_at_hash() using sha384" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $alg = 'RS384';

    # When
    my $at_hash = $access_token->compute_at_hash($alg);

    # Then
    cmp_deeply($at_hash, 'LxRf2XaJy8b6FRDyQ1Li2Zt0AoGKRvYY',
               'expected at_hash');
  };

  subtest "compute_at_hash() using sha512" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $alg = 'HS512';

    # When
    my $at_hash = $access_token->compute_at_hash($alg);

    # Then
    cmp_deeply($at_hash, 'J86UjPZx1XXXclucMfuDHRypTQyFvbe04LUmKwpgAV8',
               'expected at_hash');
  };

  subtest "compute_at_hash() unsupported alg" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $alg = 'none';

    # When - Then
    throws_ok { $access_token->compute_at_hash($alg) }
      qr/OIDC: unsupported signing algorithm: none/,
      'exception is thrown';
  };
}

sub test_verify_at_hash {
  subtest "verify_at_hash() no expected at_hash" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $expected_at_hash = undef;
    my $alg = 'HS256';

    # When
    my $result = $access_token->verify_at_hash($expected_at_hash, $alg);

    # Then
    ok($result,
       'returns a true value');
  };

  subtest "verify_at_hash() computed at_hash matches the expected one" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $expected_at_hash = 'nDwWvpw0im9HE0QZkgwo7A';
    my $alg = 'HS256';

    # When
    my $result = $access_token->verify_at_hash($expected_at_hash, $alg);

    # Then
    ok($result,
       'returns a true value');
  };

  subtest "verify_at_hash() computed at_hash doesn't match the expected one" => sub {

    # Given
    my $access_token = $class->new(
      token => 'M-oxIny1RfaFbmjMX54L8Pl-KQEPeQvF6awzjWFA3iq',
    );
    my $expected_at_hash = 'unexpectedAtHash';
    my $alg = 'HS256';

    # When - Then
    throws_ok { $access_token->verify_at_hash($expected_at_hash, $alg) }
      qr/OIDC: unexpected at_hash/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
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

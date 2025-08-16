#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client::Identity';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_has_expired {
  subtest "has_expired() - identity has expired" => sub {

    # Given
    my $identity = $class->new(
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => 12,
    );

    # When
    my $has_expired = $identity->has_expired();

    # Then
    ok($has_expired, 'has expired');
  };

  subtest "has_expired() - token has not expired" => sub {

    # Given
    my $identity = $class->new(
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => time + 5,
    );

    # When
    my $has_expired = $identity->has_expired();

    # Then
    is($has_expired, '', 'has not expired');
  };

  subtest "has_expired() - no expiration time information" => sub {

    # Given
    my $identity = $class->new(
      subject    => 'my_subject',
      claims     => {},
      token => 'my_id_token',
    );

    # When
    my $has_expired = $identity->has_expired();

    # Then
    is($has_expired, undef, 'returns undef');
  };

  subtest "has_expired() - including leeway, token has expired" => sub {

    # Given
    my $identity = $class->new(
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => time + 5,
    );

    # When
    my $has_expired = $identity->has_expired(10);

    # Then
    ok($has_expired, 'has expired');
  };

  subtest "has_expired() - including leeway, token has not expired" => sub {

    # Given
    my $identity = $class->new(
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => time + 15,
    );

    # When
    my $has_expired = $identity->has_expired(10);

    # Then
    is($has_expired, '', 'has not expired');
  };
}

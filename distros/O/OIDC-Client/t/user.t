#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client::User';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_has_role_with_role_prefix {
  subtest "has_role() with role_prefix" => sub {

    # Given
    my $user = $class->new(
      login       => 'my_login',
      lastname    => 'my_lastname',
      roles       => [qw/MY.PREFIX.ROLE-A MY.PREFIX.ROLE-B/],
      role_prefix => 'MY.PREFIX.',
    );

    {
      # When
      my $result = $user->has_role('ROLE-B');

      # Then
      ok($result, 'has role');
    }

    {
      # When
      my $result = $user->has_role('ROLE-C');

      # Then
      ok(!$result, 'has not role');
    }
  };
}

sub test_has_role_without_role_prefix {
  subtest "has_role() without role_prefix" => sub {

    # Given
    my $user = $class->new(
      login       => 'my_login',
      lastname    => 'my_lastname',
      roles       => [qw/MY.PREFIX.ROLE-A MY.PREFIX.ROLE-B/],
    );

    {
      # When
      my $result = $user->has_role('MY.PREFIX.ROLE-B');

      # Then
      ok($result, 'has role');
    }

    {
      # When
      my $result = $user->has_role('ROLE-B');

      # Then
      ok(!$result, 'has not role');
    }
  };
}

sub test_has_role_without_roles {
  subtest "has_role() without roles" => sub {

    # Given
    my $user = $class->new(
      login       => 'my_login',
      lastname    => 'my_lastname',
      firstname   => undef,
      email       => undef,
      roles       => undef,
      role_prefix => undef,
    );

    {
      # When
      my $result = $user->has_role('ROLE-B');

      # Then
      ok(!$result, 'has not role');
    }
  };
}

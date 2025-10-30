#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

use_ok 'OIDC::Client::Utils', qw/get_values_from_space_delimited_string/;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_get_values_from_space_delimited_string {
  subtest "get_values_from_space_delimited_string() with a single value" => sub {

    # Given
    my $str = 'single_value';

    # When
    my $values = get_values_from_space_delimited_string($str);

    # Then
    cmp_deeply($values, [qw/single_value/]);
  };

  subtest "get_values_from_space_delimited_string() with multiple values" => sub {

    # Given
    my $str = 'value1 value2';

    # When
    my $values = get_values_from_space_delimited_string($str);

    # Then
    cmp_deeply($values, ['value1', 'value2']);
  };

  subtest "get_values_from_space_delimited_string() with multiple spaces" => sub {

    # Given
    my $str = ' value1  value2 value3   ';

    # When
    my $values = get_values_from_space_delimited_string($str);

    # Then
    cmp_deeply($values, ['value1', 'value2', 'value3']);
  };
}

#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client::Error::Provider';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_default_message {
  subtest "default message" => sub {

    # Given
    my $error = $class->new();

    # When
    my $msg = $error->message;

    # Then
    is($msg, 'OIDC: problem returned by the provider',
       'expected message');
  };
}

sub test_message_with_only_error_in_response_parameters {
  subtest "message with only error in response parameters" => sub {

    # Given
    my $error = $class->new(
      response_parameters => {
        error => 'my_error',
      }
    );

    # When
    my $msg = $error->message;

    # Then
    is($msg, 'my_error',
       'expected message');
  };
}

sub test_message_with_error_in_response_parameters {
  subtest "message with error in response parameters" => sub {

    # Given
    my $error = $class->new(
      response_parameters => {
        error             => 'invalid_scope',
        error_description => 'Unknown/invalid requested scope(s)',
        state             => 'ab1cd',
      },
      alternative_error => '400',
    );

    # When
    my $msg = $error->message;

    # Then
    is($msg, 'invalid_scope (error_description: Unknown/invalid requested scope(s), state: ab1cd)',
       'expected message');
  };
}

sub test_message_without_error_in_response_parameters {
  subtest "message without error in response parameters" => sub {

    # Given
    my $error = $class->new(
      response_parameters => {
        a => 'b',
        c => 'd',
      },
      alternative_error => '400',
    );

    # When
    my $msg = $error->message;

    # Then
    is($msg, '400 (a: b, c: d)',
       'expected message');
  };
}

sub test_message_without_error_nor_alternative_error {
  subtest "message without error nor alternative error" => sub {

    # Given
    my $error = $class->new(
      response_parameters => {
        a => 'b',
        c => 'd',
      }
    );

    # When
    my $msg = $error->message;

    # Then
    is($msg, 'OIDC: problem returned by the provider (a: b, c: d)',
       'expected message');
  };
}

sub test_exception {
  subtest "exception" => sub {

    throws_ok {
      $class->throw();
    } qr/OIDC: problem returned by the provider/,
      'exception with default message';

    throws_ok {
      $class->throw("my custom message");
    } qr/my custom message/,
      'exception with custom message';

    throws_ok {
      $class->throw({response_parameters => {error => "my error", a => 'b'}});
    } qr/my error \(a: b\)/,
      'exception with response parameters';
  };
}

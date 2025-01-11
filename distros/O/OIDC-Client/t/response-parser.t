#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::MockObject;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client::ResponseParser';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_parse_ok {
  subtest "parse() ok" => sub {

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 1 });
    $mock_response->mock(json => sub { { a => 'b' } });
    my $response_parser = $class->new();

    # When
    my $result = $response_parser->parse($mock_response);

    # Then
    cmp_deeply($result, { a => 'b' },
               'expected result');
  };
}

sub test_parse_with_invalid_response {
  subtest "parse() with invalid response" => sub {

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 1 });
    $mock_response->mock(json => sub { die 'test' });
    my $response_parser = $class->new();

    # When - Then
    throws_ok {
      $response_parser->parse($mock_response)
    } qr/Invalid response/,
    'expected error message';
    isa_ok($@, 'OIDC::Client::Error::InvalidResponse');
  };
}

sub test_parse_with_provider_error {
  subtest "parse() with provider error, no json response" => sub {

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 0 });
    $mock_response->mock(is_error => sub { 1 });
    $mock_response->mock(message => sub {});
    $mock_response->mock(code => sub { 500 });
    $mock_response->mock(json => sub { die 'test' });
    my $response_parser = $class->new();

    # When - Then
    throws_ok {
      $response_parser->parse($mock_response)
    } qr/500/,
    'expected error message';
    isa_ok($@, 'OIDC::Client::Error::Provider');
  };
}

sub test_parse_with_provider_error_and_json_response {
  subtest "parse() with provider error and json response" => sub {

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 0 });
    $mock_response->mock(is_error => sub { 1 });
    $mock_response->mock(message => sub { 'message' });
    $mock_response->mock(code => sub { 401 });
    $mock_response->mock(json => sub { { error => 'error message',
                                         error_description => 'error description'} });
    my $response_parser = $class->new();

    # When - Then
    throws_ok {
      $response_parser->parse($mock_response)
    } qr/error message \(error_description: error description\)/,
    'expected error message';
    isa_ok($@, 'OIDC::Client::Error::Provider');
  };
}

sub test_parse_with_provider_error_and_without_json_response {
  subtest "parse() with provider error and without json response" => sub {

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 0 });
    $mock_response->mock(is_error => sub { 0 });
    $mock_response->mock(json => sub {});
    $mock_response->{error} = {code => 401};
    my $response_parser = $class->new();

    # When - Then
    throws_ok {
      $response_parser->parse($mock_response)
    } qr/401/,
    'expected error message';
    isa_ok($@, 'OIDC::Client::Error::Provider');
  };
}

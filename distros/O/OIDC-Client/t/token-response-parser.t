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

my $class = 'OIDC::Client::TokenResponseParser';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_parse_ok {
  subtest "parse() ok" => sub {

    my %token = (
      access_token => 'my_access_token',
    );

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 1 });
    $mock_response->mock(json => sub { \%token });
    my $response_parser = $class->new();

    # When
    my $result = $response_parser->parse($mock_response);

    # Then
    isa_ok($result, 'OIDC::Client::TokenResponse');
    is($result->access_token, 'my_access_token',
       'expected result');
  };
}

sub test_parse_with_exception {
  subtest "parse() with exception" => sub {

    # Given
    my $mock_response = Test::MockObject->new();
    $mock_response->mock(is_success => sub { 1 });
    $mock_response->mock(json => sub { die 'test' });
    my $response_parser = $class->new();

    # When - Then
    throws_ok {
      $response_parser->parse($mock_response)
    } 'OIDC::Client::Error::InvalidResponse',
    'expected exception';
  };
}

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

my $class = 'OIDC::Client::ApiUserAgentBuilder';
use_ok $class, qw( build_api_useragent_from_token_response
                   build_api_useragent_from_access_token
                   build_api_useragent_from_token_value
               );

launch_tests();
done_testing;

sub test_build_api_useragent_from_token_response {
  subtest "build_api_useragent_from_token_response() - with token type" => sub {

    # Given
    my $token_response = OIDC::Client::TokenResponse->new(
      access_token => 'my_token_value',
      token_type   => 'my_token_type',
    );

    # When
    my $ua = build_api_useragent_from_token_response($token_response);

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'my_token_type my_token_value');
  };

  subtest "build_api_useragent_from_token_response() - default token type" => sub {

    # Given
    my $token_response = OIDC::Client::TokenResponse->new(
      access_token => 'my_token_value',
    );

    # When
    my $ua = build_api_useragent_from_token_response($token_response);

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'Bearer my_token_value');
  };
}

sub test_build_api_useragent_from_access_token {
  subtest "build_api_useragent_from_access_token() - with token type" => sub {

    # Given
    my $access_token = OIDC::Client::AccessToken->new(
      token      => 'my_token_value',
      token_type => 'my_token_type',
    );

    # When
    my $ua = build_api_useragent_from_access_token($access_token);

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'my_token_type my_token_value');
  };

  subtest "build_api_useragent_from_access_token() - default token type" => sub {

    # Given
    my $access_token = OIDC::Client::AccessToken->new(
      token => 'my_token_value',
    );

    # When
    my $ua = build_api_useragent_from_access_token($access_token);

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'Bearer my_token_value');
  };
}

sub test_build_api_useragent_from_token_value {
  subtest "build_api_useragent_from_token_value() - with token type" => sub {

    # Given
    my $token_value = 'my_token_value';
    my $token_type  = 'my_token_type';

    # When
    my $ua = build_api_useragent_from_token_value($token_value, $token_type);

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'my_token_type my_token_value');
  };

  subtest "build_api_useragent_from_token_value() - default token type" => sub {

    # Given
    my $token_value = 'my_token_value';

    # When
    my $ua = build_api_useragent_from_token_value($token_value);

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'Bearer my_token_value');
  };
}

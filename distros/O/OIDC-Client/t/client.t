#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use feature 'state';
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Warn;
use Log::Any::Test;
use Log::Any qw($log);
use Carp qw(croak);
use Mojo::URL;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_build_with_exceptions {
  subtest "BUILD with exceptions" => sub {

    throws_ok {
      $class->new(
        provider => 'my_provider',
        secret   => 'my_client_secret',
        log      => $log,
      );
    } qr/no id/,
      'id is missing';

    throws_ok {
      $class->new(
        id     => 'my_client_id',
        secret => 'my_client_secret',
        log    => $log,
      );
    } qr/no provider/,
      'provider is missing';

    throws_ok {
      $class->new(
        log => $log,
        config => {
          provider   => 'my_provider',
          id         => 'my_client_id',
          secret     => 'my_client_secret',
          store_mode => 'cache',
        },
      );
    } qr/you cannot use the 'cache' store mode with the 'authorization_code' grant type/,
      'cache store mode incompatible with authorization_code grant type';

    throws_ok {
      $class->new(
        log => $log,
        config => {
          provider => 'my_provider',
          id       => 'my_client_id',
          secret   => 'my_client_secret',
          audience => 'my_audience',
          audience_alias => {
            alias1 => {
              audience => 'audience1',
            },
            alias2 => {
              audience => 'audience2',
            },
            alias3 => {
              audience => 'audience1',
            },
            alias4 => {
              audience => 'my_audience',
            },
          },
        },
      );
    } qr/these configured audiences are duplicated: my_audience, audience1/,
      'duplicates audiences';
  };

  throws_ok {
    $class->new(
      log    => $log,
      config => {
        provider            => 'my_provider',
        id                  => 'my_client_id',
        secret              => 'my_client_secret',
        identity_expires_in => 3600,
        bad_key             => 'dd',
      },
    );
  } qr/bad_key/,
    'unexpected key for checked configuration';
}

sub test_build_secret {
  subtest "secret from config" => sub {

    # Given
    my %config = (
      id       => 'my_client_id',
      secret   => 'my_client_secret',
      provider => 'my_provider',
    );
    my $client = $class->new(
      log    => $log,
      config => \%config,
    );

    # When - Then
    is($client->secret, 'my_client_secret',
       'from config');
  };

  subtest "secret from ENV" => sub {
    $log->clear();

    # Given
    my %config = (
      id       => 'my_client_id',
      provider => 'my_provider',
    );
    my $client = $class->new(
      log    => $log,
      config => \%config,
    );
    local $ENV{OIDC_MY_PROVIDER_SECRET} = 'secret';

    # When - Then
    is($client->secret, 'secret',
       'from environment variable');
    $log->empty_ok('no log');
  };

  subtest "'none' auth method" => sub {
    $log->clear();

    # Given
    my %config = (
      id                         => 'my_client_id',
      provider                   => 'my_provider',
      token_endpoint_auth_method => 'none',
    );
    my $client = $class->new(
      log    => $log,
      config => \%config,
    );

    # When - Then
    throws_ok { $client->secret }
      qr/no secret configured or set up in environment/,
      'secret should not be used';
  };
}

sub test_user_agent {
  subtest "user_agent" => sub {

    # Given
    my %config = (
      provider     => 'my_provider',
      id           => 'my_client_id',
      secret       => 'my_client_secret',
      proxy_detect => 1,
      user_agent   => 'my_user_agent',
    );

    # When
    my $client = $class->new(
      log    => $log,
      config => \%config,
    );

    # Then
    is($client->user_agent->transactor->name, 'my_user_agent',
       'expected user agent name');
  };
}

sub test_claim_mapping_from_config {
  subtest "claim_mapping from config" => sub {

    # Given
    my %claim_mapping = (
      login     => 'sub',
      lastname  => 'lastName',
      firstname => 'firstName',
    );
    my $client = $class->new(
      log    => $log,
      config => {
        provider      => 'my_provider',
        id            => 'my_client_id',
        secret        => 'my_client_secret',
        claim_mapping => \%claim_mapping,
      },
    );

    # When
    my $claim_mapping = $client->claim_mapping;

    # Then
    cmp_deeply($claim_mapping, \%claim_mapping,
               'from config');
  };
}

sub test_claim_mapping_from_default_value {
  subtest "claim_mapping from default value" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When
    my $claim_mapping = $client->claim_mapping;

    # Then
    my %expected = ();
    cmp_deeply($claim_mapping, \%expected,
               'from default value');
  };
}

sub test_jwt_decoding_options_from_config {
  subtest "jwt_decoding_options from config" => sub {

    # Given
    my %options = (
      verify_exp => 1,
      leeway     => 20,
    );
    my $client = $class->new(
      log    => $log,
      config => {
        provider             => 'my_provider',
        id                   => 'my_client_id',
        secret               => 'my_client_secret',
        jwt_decoding_options => \%options,
      },
    );

    # When
    my $jwt_decoding_options = $client->jwt_decoding_options;

    # Then
    cmp_deeply($jwt_decoding_options, \%options,
               'from config');
  };
}

sub test_jwt_decoding_options_from_default_value {
  subtest "jwt_decoding_options from default value" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When
    my $jwt_decoding_options = $client->jwt_decoding_options;

    # Then
    my %expected = (leeway => 60, verify_exp => 1, verify_iat => 1);
    cmp_deeply($jwt_decoding_options, \%expected,
               'from default value');
  };
}

sub test_provider_metadata_from_config {
  subtest "provider_metadata from config" => sub {
    $log->clear();

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider      => 'my_provider',
        id            => 'my_client_id',
        secret        => 'my_client_secret',
        authorize_url => 'my_authorize_url',
        jwks_url      => 'my_jwks_url',
      },
    );

    # When
    my $provider_metadata = $client->provider_metadata;

    # Then
    my %expected_provider_metadata = (
      authorize_url => 'my_authorize_url',
      jwks_url      => 'my_jwks_url',
    );
    cmp_deeply($provider_metadata, \%expected_provider_metadata,
               'retrieved from config');
    $log->empty_ok('no log');
  };
}

sub test_provider_metadata_from_well_known_url {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      get => {
        authorization_endpoint => 'provider_authorize_url',
        end_session_endpoint   => 'provider_end_session_url',
        issuer                 => 'provider_issuer',
        token_endpoint         => 'provider_token_url',
        userinfo_endpoint      => 'provider_userinfo_url',
        introspection_endpoint => 'provider_introspection_url',
        jwks_uri               => 'provider_jwks_url',
      },
    }
  );
  $test->mock_response_parser();

  subtest "provider_metadata from well_known url" => sub {
    $log->clear();

    # Given
    my $client = $class->new(
      log             => $log,
      kid_keys        => {},
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider       => 'my_provider',
        id             => 'my_client_id',
        secret         => 'my_client_secret',
        well_known_url => 'my_well_known_url',
      },
    );

    # When
    my $provider_metadata = $client->provider_metadata;

    # Then
    my %expected_provider_metadata = (
      authorize_url     => 'provider_authorize_url',
      end_session_url   => 'provider_end_session_url',
      issuer            => 'provider_issuer',
      token_url         => 'provider_token_url',
      userinfo_url      => 'provider_userinfo_url',
      introspection_url => 'provider_introspection_url',
      jwks_url          => 'provider_jwks_url',
    );

    cmp_deeply($provider_metadata, \%expected_provider_metadata,
               'retrieved from well-known url');

    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'get', [ $test->mocked_user_agent, 'my_well_known_url' ] ],
               'expected call to user agent');
    cmp_deeply($log->msgs,
               [
                 superhashof({
                   message => 'OIDC/my_provider: fetching OpenID configuration from my_well_known_url',
                   level   => 'info',
                 }),
               ],
               'expected log');
  };

  subtest "provider_metadata from well_known url + config" => sub {
    # Given
    my $client = $class->new(
      log             => $log,
      kid_keys        => {},
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider       => 'my_provider',
        id             => 'my_client_id',
        secret         => 'my_client_secret',
        well_known_url => 'my_well_known_url',
        authorize_url  => 'my_authorize_url',
      },
    );

    # When
    my $provider_metadata = $client->provider_metadata;

    # Then
    my %expected_provider_metadata = (
      authorize_url     => 'my_authorize_url',
      end_session_url   => 'provider_end_session_url',
      issuer            => 'provider_issuer',
      token_url         => 'provider_token_url',
      userinfo_url      => 'provider_userinfo_url',
      introspection_url => 'provider_introspection_url',
      jwks_url          => 'provider_jwks_url',
    );

    cmp_deeply($client->provider_metadata, \%expected_provider_metadata,
               'retrieved from well-known url + config');
  };
}

sub test_kid_keys {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      get => { keys => ['a'] },
    }
  );
  $test->mock_response_parser();

  subtest "kid_keys ok" => sub {
    $log->clear();

    # Given
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config     => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
        jwks_url => 'my_jwks_url',
        claim_mapping => {
          login => 'sub',
        }
      },
    );

    # When
    my $kid_keys = $client->kid_keys;

    # Then
    cmp_deeply($kid_keys, { keys => ['a'] },
               'retrieved from jwks url');

    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'get', [ $test->mocked_user_agent, 'my_jwks_url' ] ],
               'expected call to user agent');
    cmp_deeply($log->msgs,
               [
                 superhashof({
                   message => 'OIDC/my_provider: fetching JWT kid keys',
                   level   => 'info',
                 }),
               ],
               'expected log');
  };

  subtest "kid_keys croaks without jwks_url" => sub {
    $log->clear();

    # Given
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config     => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When - Then
    throws_ok { $client->kid_keys }
      qr/jwks_url not found in provider metadata/,
      'jwks_url is missing';
  };
}

sub test_auth_url_croaks_without_authorize_url {
  subtest "auth_url() croaks without authorize_url" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When - Then
    throws_ok { $client->auth_url() }
      qr/OIDC: authorize url not found in provider metadata/,
      'missing authorize url';
  };
}

sub test_auth_url_returning_string {
  subtest "auth_url() returning string" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => { authorize_url => 'HTtps://my-provider/authorize' },
    );

    {
      # When
      my $auth_url = $client->auth_url();

      # Then
      ok(! ref $auth_url,
         'is a scalar');

      my $mojo_auth_url = Mojo::URL->new($auth_url);

      is($mojo_auth_url->protocol, 'https',
         'expected scheme');

      is($mojo_auth_url->host, 'my-provider',
         'expected host');

      is($mojo_auth_url->path, '/authorize',
         'expected path');

      my %expected_query_params = (
        response_type => 'code',
        client_id     => 'my_client_id',
      );
      cmp_deeply($mojo_auth_url->query->to_hash, \%expected_query_params,
                 'expected query params with minimum arguments');
    }
    {
      # When
      my $auth_url = $client->auth_url(
        redirect_uri => 'my_redirect_uri',
        state        => 'my_state',
        scope        => 'my scope',
        audience     => 'my_audience',
        extra_params => { other_param1 => 'my_other_param1',
                          other_param2 => 'my_other_param2' },
      );

      # Then
      my $mojo_auth_url = Mojo::URL->new($auth_url);

      my %expected_query_params = (
        response_type => 'code',
        client_id     => 'my_client_id',
        redirect_uri  => 'my_redirect_uri',
        state         => 'my_state',
        scope         => 'my scope',
        audience      => 'my_audience',
        other_param1  => 'my_other_param1',
        other_param2  => 'my_other_param2',
      );
      cmp_deeply($mojo_auth_url->query->to_hash, \%expected_query_params,
                 'expected query params with maximum arguments');
    }
  };
}

sub test_auth_url_returning_mojo_url {
  subtest "auth_url() returning a mojo url" => sub {

    # Given
    my $client = $class->new(
      log                             => $log,
      kid_keys                        => {},
      provider                        => 'my_provider',
      id                              => 'my_client_id',
      secret                          => 'my_client_secret',
      signin_redirect_uri             => 'my_signin_redirect_uri',
      scope                           => 'my_scope',
      audience                        => 'my_audience',
      authorize_endpoint_extra_params => { other_param => 'my_other_param' },
      provider_metadata               => { authorize_url => 'HTtps://my-provider/authorize' },
    );

    # When
    my $auth_url = $client->auth_url(want_mojo_url => 1);

    # Then
    isa_ok($auth_url, 'Mojo::URL');

    is($auth_url->protocol, 'https',
       'expected scheme');

    is($auth_url->host, 'my-provider',
       'expected host');

    is($auth_url->path, '/authorize',
       'expected path');

    my %expected_query_params = (
      response_type => 'code',
      client_id     => 'my_client_id',
      redirect_uri  => 'my_signin_redirect_uri',
      scope         => 'my_scope',
      audience      => 'my_audience',
      other_param   => 'my_other_param',
    );
    cmp_deeply($auth_url->query->to_hash, \%expected_query_params,
               'expected query params with config parameters');
  };
}

sub test_get_token_croaks_without_token_url {
  subtest "get_token() croaks without token_url" => sub {

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config   => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When - Then
    throws_ok { $client->get_token(code => 'my_code') }
      qr/OIDC: token url not found in provider metadata/,
      'missing token url';
  };
}

sub test_get_token_authorization_code {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      post => { access_token => 'my_access_token' },
    }
  );
  $test->mock_token_response_parser();

  subtest "get_token() authorization_code grant type" => sub {
    $log->clear();

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        token_endpoint_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      code         => 'my_code',
      redirect_uri => 'my_redirect_uri'
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'authorization_code',
      client_id     => 'my_client_id',
      client_secret => 'my_client_secret',
      code          => 'my_code',
      redirect_uri  => 'my_redirect_uri',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
    cmp_deeply($log->msgs,
               [
                 superhashof({
                   message => 'OIDC: calling provider to get token',
                   level   => 'debug',
                 }),
               ],
               'expected log');
  };

  subtest "get_token() authorization_code grant type from config + client_secret_basic" => sub {

    # Given
    my $client = $class->new(
      log                        => $log,
      user_agent                 => $test->mocked_user_agent,
      token_response_parser      => $test->mocked_token_response_parser,
      kid_keys                   => {},
      provider                   => 'my_provider',
      id                         => 'my_client_id',
      secret                     => 'my_client_secret',
      token_endpoint_grant_type  => 'authorization_code',
      signin_redirect_uri        => 'my_signin_redirect_uri',
      audience                   => 'my_audience',
      provider_metadata          => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      code => 'my_code',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'authorization_code',
      code          => 'my_code',
      redirect_uri  => 'my_signin_redirect_uri',
      audience      => 'my_audience',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() authorization_code grant type from config + client_secret_basic" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        token_endpoint_grant_type  => 'authorization_code',
        signin_redirect_uri        => 'my_signin_redirect_uri',
        audience                   => 'my_audience',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      code => 'my_code',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'authorization_code',
      code          => 'my_code',
      redirect_uri  => 'my_signin_redirect_uri',
      audience      => 'my_audience',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() authorization_code - client_secret_jwt auth method" => sub {

    # Given
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        signin_redirect_uri        => 'my_signin_redirect_uri',
        client_auth_method         => 'client_secret_jwt',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      code => 'my_code',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');
    my %expected_encode_jwt_args = (
      alg => 'HS256',
      key => 'my_client_secret',
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'https://my-provider/token',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      grant_type            => 'authorization_code',
      code                  => 'my_code',
      redirect_uri          => 'my_signin_redirect_uri',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    my @user_agent_sended_args = $test->mocked_user_agent->next_call();
    cmp_deeply(\@user_agent_sended_args,
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
    my $client_assertion_sended_claims = $user_agent_sended_args[1][4]{client_assertion}{payload};
    is($client_assertion_sended_claims->{exp}, $client_assertion_sended_claims->{iat} + 120,
       'expected exp claim value');
  };

  subtest "get_token() authorization_code - private_key_jwt auth method" => sub {

    # Given
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $private_jwk = { kty => 'FAKE' };
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        private_jwk                => $private_jwk,
        signin_redirect_uri        => 'my_signin_redirect_uri',
        client_auth_method         => 'private_key_jwt',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      code => 'my_code',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');
    my %expected_encode_jwt_args = (
      alg => 'RS256',
      key => $private_jwk,
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'https://my-provider/token',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      grant_type            => 'authorization_code',
      code                  => 'my_code',
      redirect_uri          => 'my_signin_redirect_uri',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    my @user_agent_sended_args = $test->mocked_user_agent->next_call();
    cmp_deeply(\@user_agent_sended_args,
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
    my $client_assertion_sended_claims = $user_agent_sended_args[1][4]{client_assertion}{payload};
    is($client_assertion_sended_claims->{exp}, $client_assertion_sended_claims->{iat} + 120,
       'expected exp claim value');
  };
}

sub test_get_token_client_credentials {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      post => { access_token => 'my_access_token' },
    }
  );
  $test->mock_token_response_parser();

  subtest "get_token() client_credentials grant type" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        secret             => 'my_client_secret',
        client_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      grant_type => 'client_credentials',
      scope      => 'my_scope',
      audience   => 'my_audience',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'client_credentials',
      client_id     => 'my_client_id',
      client_secret => 'my_client_secret',
      scope         => 'my_scope',
      audience      => 'my_audience',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() client_credentials grant type from config + client_secret_basic" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        token_endpoint_grant_type  => 'client_credentials',
        token_endpoint_auth_method => 'client_secret_basic',
        scope                      => 'my_scope',
        audience                   => 'my_audience',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token();

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'client_credentials',
      scope         => 'my_scope',
      audience      => 'my_audience',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };
}

sub test_get_token_password {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      post => { access_token => 'my_access_token' },
    }
  );
  $test->mock_token_response_parser();

  subtest "get_token() password grant type" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        secret             => 'my_client_secret',
        client_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      grant_type => 'password',
      username   => 'my_username',
      password   => 'my_password',
      scope      => 'my_scope',
      audience   => 'my_audience',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'password',
      client_id     => 'my_client_id',
      client_secret => 'my_client_secret',
      username      => 'my_username',
      password      => 'my_password',
      scope         => 'my_scope',
      audience      => 'my_audience',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() password grant type from config + client_secret_basic" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        token_endpoint_grant_type  => 'password',
        token_endpoint_auth_method => 'client_secret_basic',
        username                   => 'my_username',
        password                   => 'my_password',
        scope                      => 'my_scope1 my_scope2',
        audience                   => 'my_audience',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token();

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type => 'password',
      username   => 'my_username',
      password   => 'my_password',
      scope      => 'my_scope1 my_scope2',
      audience   => 'my_audience',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };
}

sub test_get_token_refresh_token {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      post => { access_token => 'my_access_token' },
    }
  );
  $test->mock_token_response_parser();

  subtest "get_token() refresh_token grant type without scope" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        secret             => 'my_client_secret',
        scope              => 'my_scope',
        refresh_scope      => 'my_refresh_scope',
        client_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      grant_type    => 'refresh_token',
      refresh_token => 'my_refresh_token',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'refresh_token',
      client_id     => 'my_client_id',
      client_secret => 'my_client_secret',
      refresh_token => 'my_refresh_token',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() refresh_token grant type with scope" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
        scope    => 'my_scope',
        client_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      grant_type    => 'refresh_token',
      refresh_token => 'my_refresh_token',
      refresh_scope => 'my_refresh_scope',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'refresh_token',
      client_id     => 'my_client_id',
      client_secret => 'my_client_secret',
      refresh_token => 'my_refresh_token',
      scope         => 'my_refresh_scope',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() refresh_token grant type with client_secret_basic auth" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        token_endpoint_grant_type  => 'client_credentials',
        token_endpoint_auth_method => 'client_secret_basic',
        scope                      => 'my_scope',
        audience                   => 'my_audience',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      grant_type    => 'refresh_token',
      refresh_token => 'my_refresh_token',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      grant_type    => 'refresh_token',
      refresh_token => 'my_refresh_token',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "get_token() refresh_token grant type with private_key_jwt auth method" => sub {

    # Given
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      kid_keys => {},
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        private_key_file           => "$Bin/resources/client.key",
        token_endpoint_grant_type  => 'client_credentials',
        token_endpoint_auth_method => 'private_key_jwt',
        scope                      => 'my_scope',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $token_response = $client->get_token(
      grant_type    => 'refresh_token',
      refresh_token => 'my_refresh_token',
    );

    # Then
    is($token_response->access_token, 'my_access_token',
       'expected access token');
    my $expected_private_key = "FAKE PRIVATE KEY\n";
    my %expected_encode_jwt_args = (
      alg => 'RS256',
      key => \$expected_private_key,
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'https://my-provider/token',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      grant_type            => 'refresh_token',
      refresh_token         => 'my_refresh_token',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };
}

sub test_verify_jwt_token {

  # Prepare
  my $client = $class->new(
    log      => $log,
    kid_keys => {},
    config => {
      provider => 'my_provider',
      id       => 'my_client_id',
      secret   => 'my_client_secret',
    },
    provider_metadata => { issuer => 'my_issuer' },
  );

  subtest "verify_jwt_token() no 'iss' claim" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {}
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token => 'my_token',
      );
    } qr/OIDC: 'iss' claim is missing/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'iss' is different from the expected issuer" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'other_issuer',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token => 'my_token',
      );
    } qr/OIDC: unexpected issuer, expected 'my_issuer' but got 'other_issuer'/,
      'exception is thrown';
  };

  subtest "verify_jwt_token() no 'aud' claim" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token => 'my_token',
      );
    } qr/OIDC: 'aud' claim is missing/,
      'missing claim';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'aud' is the default client id" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token => 'my_token',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() 'aud' is different from the default client id" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
        aud => 'other_client_id',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token => 'my_token',
      );
    } qr/OIDC: unexpected audience, expected 'my_client_id' but got 'other_client_id'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'aud' is the expected audience" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_audience',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token             => 'my_token',
      expected_audience => 'my_audience',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() 'azp' is the default client id" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
      azp => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token                     => 'my_token',
      expected_authorized_party => 'my_client_id',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() 'azp' is different from the expected client id" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
      azp => 'other_authorized_party',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token                     => 'my_token',
        expected_authorized_party => 'my_client_id',
      );
    } qr/OIDC: unexpected authorized party, expected 'my_client_id' but got 'other_authorized_party'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() no 'azp' claim is accepted" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token                        => 'my_token',
      expected_authorized_party    => 'my_client_id',
      no_authorized_party_accepted => 1,
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() 'azp' claim is missing" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token                     => 'my_token',
        expected_authorized_party => 'my_client_id',
      );
    } qr/OIDC: 'azp' claim is missing/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() expect no 'azp' claim" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token                     => 'my_token',
      expected_authorized_party => undef,
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() unexpected 'azp' claim" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
      azp => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token                     => 'my_token',
        expected_authorized_party => undef,
      );
    } qr/OIDC: unexpected 'azp' claim/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'aud' is different from the expected client id" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
        aud => 'other_audience',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token             => 'my_token',
        expected_audience => 'my_audience',
      );
    } qr/OIDC: unexpected audience, expected 'my_audience' but got 'other_audience'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'sub' is the expected subject" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
      sub => 'my_subject',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token             => 'my_token',
      expected_subject  => 'my_subject',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() no 'sub' claim" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
        aud => 'my_client_id',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token            => 'my_token',
        expected_subject => 'my_subject',
      );
    } qr/OIDC: 'sub' claim is missing/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'sub' is different from the expected subject" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
        aud => 'my_client_id',
        sub => 'other_subject',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token            => 'my_token',
        expected_subject => 'my_subject',
      );
    } qr/OIDC: unexpected subject, expected 'my_subject' but got 'other_subject'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() 'nonce' is the expected nonce" => sub {

    # Given
    my %claims = (
      iss   => 'my_issuer',
      aud   => 'my_client_id',
      nonce => 'my_nonce',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token          => 'my_token',
      expected_nonce => 'my_nonce',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() 'nonce' is different from the expected nonce" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss   => 'my_issuer',
        aud   => 'my_client_id',
        nonce => 'other_nonce',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token          => 'my_token',
        expected_nonce => 'my_nonce',
      );
    } qr/OIDC: unexpected nonce, expected 'my_nonce' but got 'other_nonce'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() no 'nonce' is accepted" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token             => 'my_token',
      expected_nonce    => 'my_nonce',
      no_nonce_accepted => 1,
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() no 'nonce' is not accepted" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token          => 'my_token',
        expected_nonce => 'my_nonce',
      );
    } qr/OIDC: 'nonce' claim is missing/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "verify_jwt_token() age verification is ok" => sub {

    # Given
    my %claims = (
      iss   => 'my_issuer',
      aud   => 'my_client_id',
      iat   => time,
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_jwt_token(
      token         => 'my_token',
      max_token_age => 10,
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_jwt_token() token is too old" => sub {

    # Given
    my %claims = (
      iss   => 'my_issuer',
      aud   => 'my_client_id',
      iat   => time - 100,
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When - Then
    throws_ok {
      $client->verify_jwt_token(
        token         => 'my_token',
        max_token_age => 30,
      );
    } qr/OIDC: the token is too old/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };
}

sub test_verify_jwt_token_with_standard_decode_exception {
  subtest "verify_jwt_token() with a standard decode exception" => sub {

    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => {
        issuer   => 'my_issuer',
      },
    );

    # Given
    $test->mock_decode_jwt(callback => sub { croak('whatever') });

    # When - Then
    throws_ok {
      $client->verify_jwt_token(token => 'my_token');
    } qr/whatever/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };
}

sub test_verify_jwt_token_with_kid_keys_exception {
  subtest "verify_jwt_token() with 'kid_keys' exception" => sub {

    # Prepare
    $test->mock_user_agent(
      to_mock => {
        get => { keys => ['a'] },
      }
    );
    $test->mock_response_parser();

    my $client = $class->new(
      log             => $log,
      kid_keys        => {},
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => {
        issuer   => 'my_issuer',
        jwks_url => 'my_jwks_url',
      },
    );

    # Given
    $test->mock_decode_jwt(callback => sub { croak('JWE: kid_keys lookup failed') });

    # When - Then
    throws_ok {
      $client->verify_jwt_token(token => 'my_token');
    } qr/JWE: kid_keys lookup failed/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };
}

sub test_verify_jwt_token_renewing_kid_keys {
  subtest "verify_jwt_token() renewing the kid_keys" => sub {

    # Prepare
    $test->mock_user_agent(
      to_mock => {
        get => { keys => ['a', 'b', 'c'] },
      }
    );
    $test->mock_response_parser();

    my $client = $class->new(
      log             => $log,
      kid_keys        => {},
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => {
        issuer   => 'my_issuer',
        jwks_url => 'my_jwks_url',
      },
    );

    my %header = (
      alg => 'abc',
    );
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );

    # Given
    $test->mock_decode_jwt(
      callback => sub {
        state $i = 1;
        croak('JWE: kid_keys lookup failed') if $i++ == 1;
        return (\%header, \%claims);
      }
    );

    # When
    my ($token_header, $token_claims) = $client->verify_jwt_token(
      token       => 'my_token',
      want_header => 1,
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected header');
    cmp_deeply($token_claims, \%claims,
               'expected claims');
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'get', [ $test->mocked_user_agent, 'my_jwks_url' ] ],
               'expected call to renew kid keys');
    cmp_deeply($client->kid_keys, { keys => ['a', 'b', 'c'] },
               'kid keys have been updated');
  };
}

sub test_verify_token {

  # Prepare
  my $client = $class->new(
    log      => $log,
    kid_keys => {},
    config => {
      provider => 'my_provider',
      id       => 'my_client_id',
      secret   => 'my_client_secret',
    },
    provider_metadata => { issuer => 'my_issuer' },
  );

  subtest "verify_token() - 'deprecated' warning" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_audience',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When - Then
    my $token_claims;
    warning_like {
      $token_claims = $client->verify_token(
        token             => 'my_token',
        expected_audience => 'my_audience',
      );
    } 'deprecated';
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };
}

sub test_introspect_token {

  subtest "introspect_token() - 'client_secret_basic' auth method - no 'iss' nor 'aud' claim" => sub {

    # Given
    my %returned_claims = (
      active => 1,
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => { introspection_url => 'https://my-provider/introspect' },
    );

    # When
    my $claims = $client->introspect_token(
      token => 'opaque_token',
    );

    # Then
    cmp_deeply($claims, \%returned_claims,
       'expected claims');

    my %expected_args = (
      token => 'opaque_token',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/introspect', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "introspect_token() - 'client_secret_post' auth method - with token_type_hint - with expected 'iss' and 'aud' claims" => sub {

    # Given
    my %returned_claims = (
      active => 1,
      iss    => 'my_issuer',
      aud    => 'my_client_id',
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        secret             => 'my_client_secret',
        client_auth_method => 'client_secret_post',
      },
      provider_metadata => { issuer            => 'my_issuer',
                             introspection_url => 'https://my-provider/introspect' },
    );

    # When
    my $claims = $client->introspect_token(
      token           => 'opaque_token',
      token_type_hint => 'access_token',
    );

    # Then
    cmp_deeply($claims, \%returned_claims,
       'expected claims');

    my %expected_args = (
      client_id       => 'my_client_id',
      client_secret   => 'my_client_secret',
      token           => 'opaque_token',
      token_type_hint => 'access_token',
    );
    my %expected_headers = ();
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/introspect', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "introspect_token() - 'client_secret_jwt' auth method" => sub {

    # Given
    my %returned_claims = (
      active => 1,
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider                  => 'my_provider',
        id                        => 'my_client_id',
        secret                    => 'my_client_secret',
        client_auth_method        => 'client_secret_jwt',
        client_assertion_lifetime => 40,
      },
      provider_metadata => { issuer            => 'my_issuer',
                             token_url         => 'https://my-provider/token',
                             introspection_url => 'https://my-provider/introspect' },
    );

    # When
    my $claims = $client->introspect_token(
      token => 'opaque_token',
    );

    # Then
    cmp_deeply($claims, \%returned_claims,
               'expected claims');
    my %expected_encode_jwt_args = (
      alg => 'HS256',
      key => 'my_client_secret',
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'https://my-provider/introspect',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      token                 => 'opaque_token',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    my @user_agent_sended_args = $test->mocked_user_agent->next_call();
    cmp_deeply(\@user_agent_sended_args,
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/introspect', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
    my $client_assertion_sended_claims = $user_agent_sended_args[1][4]{client_assertion}{payload};
    is($client_assertion_sended_claims->{exp}, $client_assertion_sended_claims->{iat} + 40,
       'expected exp claim value');
  };

  subtest "introspect_token() - 'private_key_jwt' auth method" => sub {

    # Given
    my %returned_claims = (
      active => 1,
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $private_key = 'FAKE_PRIVATE_KEY';
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider                  => 'my_provider',
        id                        => 'my_client_id',
        private_key               => $private_key,
        client_auth_method        => 'private_key_jwt',
      },
      provider_metadata => { issuer            => 'my_issuer',
                             token_url         => 'https://my-provider/token',
                             introspection_url => 'https://my-provider/introspect' },
    );

    # When
    my $claims = $client->introspect_token(
      token => 'opaque_token',
    );

    # Then
    cmp_deeply($claims, \%returned_claims,
               'expected claims');
    my %expected_encode_jwt_args = (
      alg => 'RS256',
      key => \$private_key,
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'https://my-provider/introspect',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      token                 => 'opaque_token',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    my @user_agent_sended_args = $test->mocked_user_agent->next_call();
    cmp_deeply(\@user_agent_sended_args,
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/introspect', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "introspect_token() - 'none' auth method - inactive token" => sub {

    # Given
    my %returned_claims = (
      active => 0,
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        client_auth_method => 'none',
      },
      provider_metadata => { issuer            => 'my_issuer',
                             introspection_url => 'https://my-provider/introspect' },
    );

    # When - Then
    throws_ok {
      $client->introspect_token(token => 'opaque_token');
    } qr/OIDC: inactive token/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
    my %expected_args = (
      token     => 'opaque_token',
      client_id => 'my_client_id',
    );
    my %expected_headers = ();
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/introspect', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "introspect_token() - 'iss' is different from the expected issuer" => sub {

    # Given
    my %returned_claims = (
      active => 1,
      iss    => 'other_issuer',
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => { issuer            => 'my_issuer',
                             introspection_url => 'https://my-provider/introspect' },
    );

    # When - Then
    throws_ok {
      $client->introspect_token(token => 'opaque_token');
    } qr/OIDC: unexpected issuer, expected 'my_issuer' but got 'other_issuer'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };

  subtest "introspect_token() - 'aud' is different from the expected audience" => sub {

    # Given
    my %returned_claims = (
      active => 1,
      iss    => 'my_issuer',
      aud    => 'other_client_id',
    );
    $test->mock_user_agent(to_mock => { post => \%returned_claims });
    $test->mock_response_parser();
    my $client = $class->new(
      log             => $log,
      user_agent      => $test->mocked_user_agent,
      response_parser => $test->mocked_response_parser,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => { issuer            => 'my_issuer',
                             introspection_url => 'https://my-provider/introspect' },
    );

    # When - Then
    throws_ok {
      $client->introspect_token(token => 'opaque_token');
    } qr/OIDC: unexpected audience, expected 'my_client_id' but got 'other_client_id'/,
      'exception is thrown';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };
}

sub test_get_userinfo {

  my $userinfo_url = 'https://my-provider/userinfo';
  my %userinfo = (lastname => 'Doe');

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      get => \%userinfo,
    }
  );
  $test->mock_response_parser();

  # Given
  my $client = $class->new(
    log             => $log,
    user_agent      => $test->mocked_user_agent,
    response_parser => $test->mocked_response_parser,
    config => {
      provider => 'my_provider',
      id       => 'my_client_id',
      secret   => 'my_client_secret',
    },
    provider_metadata => { userinfo_url => $userinfo_url },
  );

  subtest "get_userinfo() without token type" => sub {

    # When
    my $userinfo = $client->get_userinfo(
      access_token => 'my_access_token',
      token_type   => undef,
    );

    # Then
    cmp_deeply($userinfo, \%userinfo,
               'expected userinfo');

    my %expected_headers = (
      Authorization => 'Bearer my_access_token',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'get', [ $test->mocked_user_agent, $userinfo_url, \%expected_headers ] ],
               'expected call to user agent');
  };

  subtest "get_userinfo() with token type" => sub {

    # When
    my $userinfo = $client->get_userinfo(
      access_token => 'my_access_token',
      token_type   => 'my_token_type',
    );

    # Then
    cmp_deeply($userinfo, \%userinfo,
               'expected userinfo');

    my %expected_headers = (
      Authorization => 'my_token_type my_access_token',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'get', [ $test->mocked_user_agent, $userinfo_url, \%expected_headers ] ],
               'expected call to user agent');
  };
}

sub test_get_audience_for_alias {
  subtest "get_audience_for_alias()" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider       => 'my_provider',
        id             => 'my_client_id',
        secret         => 'my_client_secret',
        audience_alias => {
          alias1 => {
            audience => 'audience1',
          },
          alias2 => {
            audience => 'audience2',
          },
        },
      },
    );

    {
      # When
      my $audience = $client->get_audience_for_alias('alias2');

      # Then
      is($audience, 'audience2',
         'expected audience');
    }
    {
      # When
      my $audience = $client->get_audience_for_alias('alias3');

      # Then
      is($audience, undef,
         'audience not found');
    }
  };
}

sub test_get_scope_for_audience {
  subtest "get_scope_for_audience()" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider       => 'my_provider',
        id             => 'my_client_id',
        secret         => 'my_client_secret',
        audience_alias => {
          alias1 => {
            audience => 'audience1',
          },
          alias2 => {
            audience => 'audience2',
            scope    => 'scope_audience2',
          },
        },
      },
    );

    {
      # When
      my $scope = $client->get_scope_for_audience('audience1');

      # Then
      is($scope, undef,
         'no scope');
    }
    {
      # When
      my $scope = $client->get_scope_for_audience('audience2');

      # Then
      is($scope, 'scope_audience2',
         'expected scope');
    }
  };
}

sub test_exchange_token {

  # Prepare
  $test->mock_user_agent(
    to_mock => {
      post => { access_token => 'my_access_token' },
    }
  );
  $test->mock_token_response_parser();

  subtest "exchange_token() without scope" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      config => {
        provider                   => 'my_provider',
        id                         => 'my_client_id',
        secret                     => 'my_client_secret',
        token_endpoint_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $exchanged_token = $client->exchange_token(
      token    => 'my_token',
      audience => 'my_audience',
    );

    # Then
    is($exchanged_token->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      client_id          => 'my_client_id',
      client_secret      => 'my_client_secret',
      audience           => 'my_audience',
      grant_type         => 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token      => 'my_token',
      subject_token_type => 'urn:ietf:params:oauth:token-type:access_token',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "exchange_token() with scope in parameters" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        secret             => 'my_client_secret',
        client_auth_method => 'client_secret_post',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $exchanged_token = $client->exchange_token(
      token    => 'my_token',
      audience => 'my_audience',
      scope    => 'my_scope1 my_scope2',
    );

    # Then
    is($exchanged_token->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      client_id          => 'my_client_id',
      client_secret      => 'my_client_secret',
      audience           => 'my_audience',
      scope              => 'my_scope1 my_scope2',
      grant_type         => 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token      => 'my_token',
      subject_token_type => 'urn:ietf:params:oauth:token-type:access_token',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', {}, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "exchange_token() with scope in config" => sub {

    # Given
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
        audience_alias => {
          my_alias => {
            audience => 'my_audience',
            scope    => 'my_scope1 my_scope2',
          },
        },
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $exchanged_token = $client->exchange_token(
      token    => 'my_token',
      audience => 'my_audience',
    );

    # Then
    is($exchanged_token->access_token, 'my_access_token',
       'expected access token');

    my %expected_args = (
      audience           => 'my_audience',
      scope              => 'my_scope1 my_scope2',
      grant_type         => 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token      => 'my_token',
      subject_token_type => 'urn:ietf:params:oauth:token-type:access_token',
    );
    my %expected_headers = (
      Authorization => 'Basic bXlfY2xpZW50X2lkOm15X2NsaWVudF9zZWNyZXQ=',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "exchange_token() - client_secret_jwt auth method" => sub {

    # Given
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      config => {
        provider                  => 'my_provider',
        id                        => 'my_client_id',
        secret                    => 'my_client_secret',
        client_auth_method        => 'client_secret_jwt',
        client_assertion_audience => 'my_client_assertion_audience',
        audience_alias => {
          my_alias => {
            audience => 'my_audience',
          },
        },
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $exchanged_token = $client->exchange_token(
      token    => 'my_token',
      audience => 'my_audience',
    );

    # Then
    is($exchanged_token->access_token, 'my_access_token',
       'expected access token');
    my %expected_encode_jwt_args = (
      alg => 'HS256',
      key => 'my_client_secret',
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'my_client_assertion_audience',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      audience              => 'my_audience',
      grant_type            => 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token         => 'my_token',
      subject_token_type    => 'urn:ietf:params:oauth:token-type:access_token',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    my @user_agent_sended_args = $test->mocked_user_agent->next_call();
    cmp_deeply(\@user_agent_sended_args,
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "exchange_token() - private_key_jwt auth method" => sub {

    # Given
    $test->mock_encode_jwt();  # encode_jwt() args are placed directly into 'client_assertion'
    my $client = $class->new(
      log                   => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      config => {
        provider                  => 'my_provider',
        id                        => 'my_client_id',
        private_jwk_file          => "$Bin/resources/client.jwk",
        client_auth_method        => 'private_key_jwt',
        client_assertion_audience => 'my_client_assertion_audience',
        audience_alias => {
          my_alias => {
            audience => 'my_audience',
          },
        },
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $exchanged_token = $client->exchange_token(
      token    => 'my_token',
      audience => 'my_audience',
    );

    # Then
    is($exchanged_token->access_token, 'my_access_token',
       'expected access token');
    my %expected_encode_jwt_args = (
      alg => 'RS256',
      key => {kty => 'FAKE'},
      payload => {
        iss => 'my_client_id',
        sub => 'my_client_id',
        aud => 'my_client_assertion_audience',
        jti => re('\w+'),
        iat => re('\d+'),
        exp => re('\d+'),
      },
    );
    my %expected_args = (
      audience              => 'my_audience',
      grant_type            => 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token         => 'my_token',
      subject_token_type    => 'urn:ietf:params:oauth:token-type:access_token',
      client_id             => 'my_client_id',
      client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion      => \%expected_encode_jwt_args,
    );
    my %expected_headers = ();
    my @user_agent_sended_args = $test->mocked_user_agent->next_call();
    cmp_deeply(\@user_agent_sended_args,
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', \%expected_headers, 'form', \%expected_args ] ],
               'expected call to user agent');
  };
}

sub test_build_api_useragent {
  subtest "build_api_useragent() with token parameter" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );
    my $token_type = 'my_token_type';
    my $token      = 'my_token';

    # When
    my $ua;
    warning_like {
      $ua = $client->build_api_useragent(
        token_type => $token_type,
        token      => $token,
      );
    } 'deprecated';

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
  };

  subtest "build_api_useragent() without token parameter" => sub {

    # Prepare
    $test->mock_user_agent(
      to_mock => {
        post => { access_token => 'my_access_token' },
      }
    );
    $test->mock_token_response_parser();

    # Given
    my $client = $class->new(
      log      => $log,
      user_agent            => $test->mocked_user_agent,
      token_response_parser => $test->mocked_token_response_parser,
      config => {
        provider                  => 'my_provider',
        id                        => 'my_client_id',
        secret                    => 'my_client_secret',
        audience                  => 'my_audience',
        scope                     => 'roles',
        token_endpoint_grant_type => 'password',
        username                  => 'TSTUSER',
        password                  => 'XXXXXXX',
      },
      provider_metadata => { token_url => 'https://my-provider/token' },
    );

    # When
    my $ua = $client->build_api_useragent();

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
  };
}

sub test_logout_url_croaks_without_end_session_url {
  subtest "logout_url() croaks without end_session_url" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When - Then
    throws_ok { $client->logout_url() }
      qr/OIDC: end_session_url not found in provider metadata/,
      'exception';
  };
}

sub test_logout_url_returning_string {
  subtest "logout_url() returning string" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
      provider_metadata => { end_session_url => 'https://my-provider/logout' },
    );

    {
      # When
      my $logout_url = $client->logout_url();

      # Then
      ok(! ref $logout_url,
         'is a scalar');

      my $mojo_logout_url = Mojo::URL->new($logout_url);

      is($mojo_logout_url->protocol, 'https',
         'expected scheme');

      is($mojo_logout_url->host, 'my-provider',
         'expected host');

      is($mojo_logout_url->path, '/logout',
         'expected path');

      my %expected_query_params = (
        client_id => 'my_client_id',
      );
      cmp_deeply($mojo_logout_url->query->to_hash, \%expected_query_params,
                 'expected query params with minimum arguments');
    }
    {
      # When
      my $logout_url = $client->logout_url(
        id_token                 => 'my_id_token',
        state                    => 'my_state',
        post_logout_redirect_uri => 'my_post_logout_redirect_uri',
        extra_params             => { other_param => 'my_other_param' },
      );

      # Then
      my $mojo_logout_url = Mojo::URL->new($logout_url);

      my %expected_query_params = (
        client_id                => 'my_client_id',
        id_token_hint            => 'my_id_token',
        state                    => 'my_state',
        post_logout_redirect_uri => 'my_post_logout_redirect_uri',
        other_param              => 'my_other_param',
      );
      cmp_deeply($mojo_logout_url->query->to_hash, \%expected_query_params,
                 'expected query params with maximum arguments');
    }
  };
}

sub test_logout_url_returning_mojo_url {
  subtest "logout_url() returning a mojo url" => sub {

    # Given
    my $client = $class->new(
      log    => $log,
      config => {
        provider                 => 'my_provider',
        id                       => 'my_client_id',
        secret                   => 'my_client_secret',
        post_logout_redirect_uri => 'my_post_logout_redirect_uri',
        logout_extra_params      => { other_param => 'my_other_param' },
      },
      provider_metadata => { end_session_url => 'https://my-provider/logout' },
    );

    # When
    my $logout_url = $client->logout_url(
      id_token      => 'my_id_token',
      want_mojo_url => 1
    );

    # Then
    isa_ok($logout_url, 'Mojo::URL');

    is($logout_url->protocol, 'https',
       'expected scheme');

    is($logout_url->host, 'my-provider',
       'expected host');

    is($logout_url->path, '/logout',
       'expected path');

    my %expected_query_params = (
      client_id                => 'my_client_id',
      id_token_hint            => 'my_id_token',
      post_logout_redirect_uri => 'my_post_logout_redirect_uri',
      other_param              => 'my_other_param',
    );
    cmp_deeply($logout_url->query->to_hash, \%expected_query_params,
               'expected query params with config parameters');
  };
}

sub test_get_claim_value {
  subtest "get_claim_value()" => sub {

    # Given
    my %claims = (
      sub => 'my_subject',
      exp => 1234,
      resource_access => {
        account => {
          roles => [qw/role1 role2/],
        }
      }
    );
    my %claim_mapping = (
      login     => 'sub',
      last_name => 'lastName',
      roles     => 'resource_access.account.roles',
    );
    my $client = $class->new(
      log    => $log,
      config => {
        provider      => 'my_provider',
        id            => 'my_client_id',
        secret        => 'my_client_secret',
        claim_mapping => \%claim_mapping,
      },
    );

    {
      # When
      my $claim_value = $client->get_claim_value(
        name   => 'login',
        claims => \%claims,
      );

      # Then
      is($claim_value, 'my_subject',
         'expected claim value');
    }
    {
      # When
      my $claim_value = $client->get_claim_value(
        name     => 'roles',
        claims   => \%claims,
        optional => 1,
      );

      # Then
      cmp_deeply($claim_value, [qw/role1 role2/],
                 'expected claim value for extended name');
    }
    {
      # When
      my $claim_value = $client->get_claim_value(
        name     => 'last_name',
        claims   => \%claims,
        optional => 1,
      );

      # Then
      is($claim_value, undef,
         'not present in claims and optional');
    }
    {
      # When - Then
      throws_ok {
        $client->get_claim_value(
          name   => 'last_name',
          claims => \%claims,
        );
      } qr/OIDC: the 'lastName' key is not present/,
        'not present in claims and required';
    }
    {
      # When - Then
      throws_ok {
        $client->get_claim_value(
          name     => 'first_name',
          claims   => \%claims,
          optional => 1,
        );
      } qr/OIDC: no claim key in config for name 'first_name'/,
        'claim key not present in config';
    }
  };
}

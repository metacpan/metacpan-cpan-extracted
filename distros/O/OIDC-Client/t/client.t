#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use feature 'state';
use Test::More;
use Test::Deep;
use Test::Exception;
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
        provider => 'my_provider',
        id       => 'my_client_id',
        log      => $log,
      );
    } qr/no secret/,
      'secret is missing';

    throws_ok {
      $class->new(
        provider => 'my_provider',
        id     => 'my_client_id',
        secret => 'my_client_secret',
        log    => $log,
      );
    } qr/jwks_url not found in provider metadata/,
      'jwks_url is missing';

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
      log      => $log,
      kid_keys => {},
      config   => {
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

sub test_secret_from_config {
  subtest "secret from config" => sub {

    # Given
    my %config = (
      id       => 'my_client_id',
      secret   => 'my_client_secret',
      provider => 'my_provider',
    );

    # When
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config   => \%config,
    );

    # Then
    is($client->secret, 'my_client_secret',
       'from config');
  };
}

sub test_secret_from_env {
  subtest "secret from ENV" => sub {

    # Given
    my %config = (
      id       => 'my_client_id',
      provider => 'my_provider',
    );

    # When - Then
    throws_ok {
      $class->new(
        log      => $log,
        kid_keys => {},
        config   => \%config,
      );
    } qr/OIDC: no secret configured or set up in environment/,
      'missing secret';

    # Given
    local $ENV{OIDC_MY_PROVIDER_SECRET} = 'secret';

    # When
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config   => \%config,
    );

    # Then
    is($client->secret, 'secret',
       'from environment variable');
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
      log      => $log,
      kid_keys => {},
      config   => \%config,
    );

    # Then
    is($client->user_agent->transactor->name, 'my_user_agent',
       'expected user agent name');
  };
}

sub test_claim_mapping_from_config {
  subtest "claim_mapping from config" => sub {

    # Given
    my %claim_key = (
      login     => 'sub',
      lastname  => 'lastName',
      firstname => 'firstName',
    );
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider      => 'my_provider',
        id            => 'my_client_id',
        secret        => 'my_client_secret',
        claim_mapping => \%claim_key,
      },
    );

    # When
    my $claim_mapping = $client->claim_mapping;

    # Then
    cmp_deeply($claim_mapping, \%claim_key,
               'from config');
  };
}

sub test_claim_mapping_from_default_value {
  subtest "claim_mapping from default value" => sub {

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
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

sub test_decode_jwt_options_from_config {
  subtest "decode_jwt_options from config" => sub {

    # Given
    my %options = (
      verify_exp => 1,
      leeway     => 20,
    );
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider           => 'my_provider',
        id                 => 'my_client_id',
        secret             => 'my_client_secret',
        decode_jwt_options => \%options,
      },
    );

    # When
    my $decode_jwt_options = $client->decode_jwt_options;

    # Then
    cmp_deeply($decode_jwt_options, \%options,
               'from config');
  };
}

sub test_decode_jwt_options_from_default_value {
  subtest "decode_jwt_options from default value" => sub {

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );

    # When
    my $decode_jwt_options = $client->decode_jwt_options;

    # Then
    my %expected = (leeway => 60);
    cmp_deeply($decode_jwt_options, \%expected,
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
      authorize_url   => 'provider_authorize_url',
      end_session_url => 'provider_end_session_url',
      issuer          => 'provider_issuer',
      token_url       => 'provider_token_url',
      userinfo_url    => 'provider_userinfo_url',
      jwks_url        => 'provider_jwks_url',
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
      authorize_url   => 'my_authorize_url',
      end_session_url => 'provider_end_session_url',
      issuer          => 'provider_issuer',
      token_url       => 'provider_token_url',
      userinfo_url    => 'provider_userinfo_url',
      jwks_url        => 'provider_jwks_url',
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

  subtest "kid_keys" => sub {
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
}

sub test_auth_url_croaks_without_authorize_url {
  subtest "auth_url() croaks without authorize_url" => sub {

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
    throws_ok { $client->auth_url() }
      qr/OIDC: authorize url not found in provider metadata/,
      'missing authorize url';
  };
}

sub test_auth_url_returning_string {
  subtest "auth_url() returning string" => sub {

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
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
      log      => $log,
      kid_keys => {},
      config => {
        provider            => 'my_provider',
        id                  => 'my_client_id',
        secret              => 'my_client_secret',
        signin_redirect_uri => 'my_signin_redirect_uri',
        scope               => 'my_scope',
        audience            => 'my_audience',
        authorize_endpoint_extra_params => { other_param => 'my_other_param' },
      },
      provider_metadata => { authorize_url => 'HTtps://my-provider/authorize' },
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
    throws_ok { $client->get_token() }
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
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
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

  subtest "get_token() authorization_code grant type from config + basic" => sub {

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
        token_endpoint_auth_method => 'basic',
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
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
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

  subtest "get_token() client_credentials grant type from config + basic" => sub {

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
        token_endpoint_auth_method => 'basic',
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
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
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

  subtest "get_token() password grant type from config + basic" => sub {

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
        token_endpoint_auth_method => 'basic',
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

  subtest "get_token() password grant type" => sub {

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

  subtest "get_token() password grant type with basic auth" => sub {

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
        token_endpoint_auth_method => 'basic',
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

  subtest "verify_token() missing 'aud' claim" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_token(
        token => 'my_token',
      );
    } qr/OIDC: the audience is not defined/,
      'missing claim';
  };

  subtest "verify_token() 'aud' is the default client id" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_token(
      token => 'my_token',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_token() 'aud' is different from the default client id" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
        aud => 'other_client_id',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_token(
        token => 'my_token',
      );
    } qr/OIDC: unexpected audience, expected 'my_client_id' but got 'other_client_id'/,
      'exception is thrown';
  };

  subtest "verify_token() 'aud' is the expected audience" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_audience',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_token(
      token             => 'my_token',
      expected_audience => 'my_audience',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_token() 'aud' is different from the expected client id" => sub {

    # Given
    $test->mock_decode_jwt(
      claims => {
        iss => 'my_issuer',
        aud => 'other_audience',
      }
    );

    # When - Then
    throws_ok {
      $client->verify_token(
        token             => 'my_token',
        expected_audience => 'my_audience',
      );
    } qr/OIDC: unexpected audience, expected 'my_audience' but got 'other_audience'/,
      'exception is thrown';
  };

  subtest "verify_token() 'sub' is the expected subject" => sub {

    # Given
    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
      sub => 'my_subject',
    );
    $test->mock_decode_jwt(claims => \%claims);

    # When
    my $token_claims = $client->verify_token(
      token             => 'my_token',
      expected_subject  => 'my_subject',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');
  };

  subtest "verify_token() 'sub' is different from the expected subject" => sub {

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
      $client->verify_token(
        token            => 'my_token',
        expected_subject => 'my_subject',
      );
    } qr/OIDC: unexpected subject, expected 'my_subject' but got 'other_subject'/,
      'exception is thrown';
  };
}

sub test_verify_token_with_standard_decode_exception {
  subtest "verify_token() with a standard decode exception" => sub {

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
      $client->verify_token(token => 'my_token');
    } qr/whatever/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };
}

sub test_verify_token_with_kid_keys_exception {
  subtest "verify_token() with 'kid_keys' exception" => sub {

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
      $client->verify_token(token => 'my_token');
    } qr/JWE: kid_keys lookup failed/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::TokenValidation');
  };
}

sub test_verify_token_renewing_kid_keys {
  subtest "verify_token() renewing the kid_keys" => sub {

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

    my %claims = (
      iss => 'my_issuer',
      aud => 'my_client_id',
    );

    # Given
    $test->mock_decode_jwt(
      callback => sub {
        state $i = 1;
        croak('JWE: kid_keys lookup failed') if $i++ == 1;
        return \%claims;
      }
    );

    # When
    my $token_claims = $client->verify_token(
      token => 'my_token',
    );

    # Then
    cmp_deeply($token_claims, \%claims,
               'expected claims');

    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'get', [ $test->mocked_user_agent, 'my_jwks_url' ] ],
               'expected call to renew kid keys');

    cmp_deeply($client->kid_keys, { keys => ['a', 'b', 'c'] },
               'kid keys have been updated');
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
    kid_keys => {},
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
      log      => $log,
      kid_keys => {},
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
      log      => $log,
      kid_keys => {},
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
      kid_keys => {},
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
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
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "exchange_token() with scope in parameters" => sub {

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
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', 'form', \%expected_args ] ],
               'expected call to user agent');
  };

  subtest "exchange_token() with scope in config" => sub {

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
      client_id          => 'my_client_id',
      client_secret      => 'my_client_secret',
      audience           => 'my_audience',
      scope              => 'my_scope1 my_scope2',
      grant_type         => 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token      => 'my_token',
      subject_token_type => 'urn:ietf:params:oauth:token-type:access_token',
    );
    cmp_deeply([ $test->mocked_user_agent->next_call() ],
               [ 'post', [ $test->mocked_user_agent, 'https://my-provider/token', 'form', \%expected_args ] ],
               'expected call to user agent');
  };
}

sub test_build_api_useragent {
  subtest "build_api_useragent() with token parameter" => sub {

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider => 'my_provider',
        id       => 'my_client_id',
        secret   => 'my_client_secret',
      },
    );
    my $token_type = 'my_token_type';
    my $token      = 'my_token';

    # When
    my $ua = $client->build_api_useragent(
      token_type => $token_type,
      token      => $token,
    );

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'my_token_type my_token');
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
      kid_keys => {},
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
    my $tx = $ua->build_tx(GET => 'localhost');
    $tx = $ua->start($tx);
    is($tx->req->headers->authorization, 'Bearer my_access_token');
  };
}

sub test_logout_url_croaks_without_end_session_url {
  subtest "logout_url() croaks without end_session_url" => sub {

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
    throws_ok { $client->logout_url() }
      qr/OIDC: end_session_url not found in provider metadata/,
      'exception';
  };
}

sub test_logout_url_returning_string {
  subtest "logout_url() returning string" => sub {

    # Given
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
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
      log      => $log,
      kid_keys => {},
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
      'sub' => 'my_subject',
    );
    my %claim_key = (
      login     => 'sub',
      last_name => 'lastName',
    );
    my $client = $class->new(
      log      => $log,
      kid_keys => {},
      config => {
        provider      => 'my_provider',
        id            => 'my_client_id',
        secret        => 'my_client_secret',
        claim_mapping => \%claim_key,
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
      } qr/OIDC: the 'lastName' claim is not present/,
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

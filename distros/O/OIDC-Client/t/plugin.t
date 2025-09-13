#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;
use Test::MockObject;
use Log::Any::Test;
use Log::Any qw($log);
use OIDC::Client::AccessToken;
use OIDC::Client::TokenResponse;
use OIDC::Client::User;
use Mojo::UserAgent;

use FindBin qw($Bin);
use lib "$Bin/lib";
use OIDCClientTest qw(launch_tests);

my $class = 'OIDC::Client::Plugin';
use_ok $class;

my $test = OIDCClientTest->new();

launch_tests();
done_testing;

sub test_login_redirect_uri {
  subtest "login_redirect_uri with path configuration" => sub {

    # Given
    my $obj = build_object(config => {signin_redirect_path => '/oidc/redirect'});

    # When
    my $login_redirect_uri = $obj->login_redirect_uri;

    # Then
    is($login_redirect_uri, 'http://my-app/oidc/redirect',
       'expected login_redirect_uri');
  };

  subtest "login_redirect_uri without path configuration" => sub {

    # Given
    my $obj = build_object();

    # When
    my $login_redirect_uri = $obj->login_redirect_uri;

    # Then
    is($login_redirect_uri, undef,
       'no login_redirect_uri');
  };
}

sub test_logout_redirect_uri {
  subtest "logout_redirect_uri with path configuration" => sub {

    # Given
    my $obj = build_object(config => {logout_redirect_path => '/oidc/logout/redirect'});

    # When
    my $logout_redirect_uri = $obj->logout_redirect_uri;

    # Then
    is($logout_redirect_uri, 'http://my-app/oidc/logout/redirect',
       'expected logout_redirect_uri');
  };

  subtest "logout_redirect_uri without path configuration" => sub {

    # Given
    my $obj = build_object();

    # When
    my $logout_redirect_uri = $obj->logout_redirect_uri;

    # Then
    is($logout_redirect_uri, undef,
       'no logout_redirect_uri');
  };
}

sub test_redirect_to_authorize_with_maximum_parameters {
  subtest "redirect_to_authorize() with maximum of parameters" => sub {

    # Given
    my $obj = build_object(attributes => { login_redirect_uri => 'my_login_redirect_uri' });

    # When
    $obj->redirect_to_authorize(
      target_url         => 'my_target_url',
      extra_params       => { param => 'param' },
      other_state_params => [ 'state_param1', 'state_param2' ],
    );

    # Then
    my ($state, $auth_data) = get_auth_data($obj);
    cmp_deeply($state, re('^state_param1,state_param2,[\w-]{36,36}$'),
               'expected state');
    cmp_deeply($auth_data,
               { nonce      => re('^[\w-]{36,36}$'),
                 provider   => 'my_provider',
                 target_url => 'my_target_url' },
               'expected oidc_auth session data');

    is($obj->redirect->(), 'my_auth_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call() ],
               [ 'auth_url', bag($obj->client, nonce        => $auth_data->{nonce},
                                               state        => $state,
                                               redirect_uri => 'my_login_redirect_uri',
                                               extra_params => { param => 'param' }) ],
               'expected call to client');
  };
}

sub test_redirect_to_authorize_with_minimum_parameters {
  subtest "redirect_to_authorize() with minimum of parameters" => sub {

    # Given
    my $obj = build_object(attributes => { login_redirect_uri => undef });

    # When
    $obj->redirect_to_authorize();

    # Then
    my ($state, $auth_data) = get_auth_data($obj);
    cmp_deeply($state, re('^[\w-]{36,36}$'),
               'expected state');
    cmp_deeply($auth_data,
               { nonce      => re('^[\w-]{36,36}$'),
                 provider   => 'my_provider',
                 target_url => '/current-url' },
               'expected oidc_auth session data');

    is($obj->redirect->(), 'my_auth_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call() ],
               [ 'auth_url', bag($obj->client, nonce => $auth_data->{nonce},
                                               state => $state) ],
               'expected call to client');
  };
}

sub test_get_token_with_provider_error {
  subtest "get_token() with provider error" => sub {

    # Given
    my $obj = build_object(request_params => {error => 'error from provider'});

    # When - Then
    throws_ok { $obj->get_token() }
      qr/error from provider/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Provider');
  };
}

sub test_get_token_with_invalid_state_parameter {
  subtest "get_token() without state parameter" => sub {

    # Given
    my $obj = build_object(request_params => {});

    # When - Then
    throws_ok { $obj->get_token() }
      qr/no state parameter/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Authentication');
  };

  subtest "get_token() without authorisation data in session" => sub {

    # Given
    my $obj = build_object(request_params => {state => 'aaa'});

    # When - Then
    throws_ok { $obj->get_token() }
      qr/no authorisation data for state : 'aaa'/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Authentication');
  };
}

sub test_get_token_ok {
  subtest "get_token() with all tokens" => sub {

    # Given
    my $obj = build_object(request_params => {code  => 'my_code',
                                              state => 'abc'},
                           token_response => {id_token      => 'my_id_token',
                                              access_token  => 'my_access_token',
                                              refresh_token => 'my_refresh_token',
                                              token_type    => 'my_token_type',
                                              expires_in    => 3600,
                                              scope         => 'openid scope'});
    set_auth_data($obj, 'abc' => {nonce => 'my-nonce'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    my %expected_stored_identity = (
      subject    => 'my_subject',
      token      => 'my_id_token',
      expires_at => 1111111,
      claims     => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        roles => [qw/role1 role2 role3/],
      },
    );
    isa_ok($identity, 'OIDC::Client::Identity');
    cmp_deeply($identity,
               noclass(\%expected_stored_identity),
               'expected returned identity');
    cmp_deeply(get_identity($obj),
               \%expected_stored_identity,
               'expected stored identity');
    my $expected_stored_access_token = {
      expires_at => re('^\d+$'),
      token      => 'my_access_token',
      token_type => 'my_token_type',
      scopes     => [qw/openid scope/],
    };
    cmp_deeply(get_access_token($obj),
               $expected_stored_access_token,
               'expected stored access token');
    cmp_deeply(get_refresh_token($obj),
               'my_refresh_token',
               'expected stored refresh token');
    cmp_deeply([ $obj->client->next_call() ],
               [ 'get_token', [ $obj->client, code         => 'my_code',
                                              redirect_uri => 'my_redirect_uri' ] ],
               'expected call to client->get_token');
    cmp_deeply([ $obj->client->next_call(2) ],
               [ 'verify_token', [ $obj->client, token             => 'my_id_token',
                                                 expected_audience => 'my_id',
                                                 expected_nonce    => 'my-nonce'] ],
               'expected call to client->verify_token');

    my ($state, $auth_data) = get_auth_data($obj);
    ok(!defined $state && !defined $auth_data,
       'auth_data has been deleted');
  };

  subtest "get_token() with only ID token" => sub {

    # Given
    my $obj = build_object(request_params => {code     => 'my_code',
                                              state    => 'abc'},
                           token_response => {id_token => 'my_id_token'});
    set_auth_data($obj, 'abc' => {nonce => 'my-nonce'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    my %expected_stored_identity = (
      subject    => 'my_subject',
      token      => 'my_id_token',
      expires_at => 1111111,
      claims     => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        roles => [qw/role1 role2 role3/],
      },
    );
    isa_ok($identity, 'OIDC::Client::Identity');
    cmp_deeply($identity,
               noclass(\%expected_stored_identity),
               'expected returned identity');
    cmp_deeply(get_identity($obj),
               \%expected_stored_identity,
               'expected stored identity');
    cmp_deeply(get_access_token($obj),
               undef,
               'no stored access token');
  };

  subtest "get_token() - identity expires in configured number of seconds" => sub {

    # Given
    my $expires_in = 3600;
    my $obj = build_object(request_params => {code                => 'my_code',
                                              state               => 'abc'},
                           token_response => {id_token            => 'my_id_token'},
                           config         => {identity_expires_in => $expires_in});
    set_auth_data($obj, 'abc' => {nonce => 'my-nonce'});

    # When
    my $begin_time = time;
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    cmp_deeply($identity->{expires_at},
               num($begin_time + $expires_in, 1),
               'expected expires_at');
  };

  subtest "get_token() - no identity expiration" => sub {

    # Given
    my $obj = build_object(request_params => {code                => 'my_code',
                                              state               => 'abc'},
                           token_response => {id_token            => 'my_id_token'},
                           config         => {identity_expires_in => 0});
    set_auth_data($obj, 'abc' => {nonce => 'my-nonce'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    ok(! defined $identity->expires_at,
       'no expires_at');
  };

  subtest "get_token() with only access token" => sub {

    # Given
    my $obj = build_object(request_params => {code         => 'my_code',
                                              state        => 'abc'},
                           token_response => {access_token => 'my_access_token'});
    set_auth_data($obj, 'abc' => {nonce => 'my-nonce'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    cmp_deeply($identity,
               undef,
               'no returned identity');
    cmp_deeply(get_identity($obj),
               undef,
               'no stored identity');
    my $expected_stored_access_token = {
      token => 'my_access_token',
    };
    cmp_deeply(get_access_token($obj),
               $expected_stored_access_token,
               'expected stored access token');
    cmp_deeply(get_refresh_token($obj),
               undef,
               'no stored refresh token');
  };

  subtest "get_token() with access token and refresh token" => sub {

    # Given
    my $obj = build_object(request_params => {code          => 'my_code',
                                              state         => 'abc'},
                           token_response => {access_token  => 'my_access_token',
                                              refresh_token => 'my_refresh_token'});
    set_auth_data($obj, 'abc' => {nonce => 'my-nonce'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    cmp_deeply($identity,
               undef,
               'no returned identity');
    cmp_deeply(get_identity($obj),
               undef,
               'no stored identity');
    my $expected_stored_access_token = {
      token => 'my_access_token',
    };
    cmp_deeply(get_access_token($obj),
               $expected_stored_access_token,
               'expected stored access token'
             );
    cmp_deeply(get_refresh_token($obj),
               'my_refresh_token',
               'expected stored refresh token');
  };
}

sub test_refresh_token_with_exceptions {
  subtest "refresh_token() with unknown_audience" => sub {

    # Given
    my $obj = build_object();
    $obj->client->mock('get_audience_for_alias', sub {});

    # When - Then
    throws_ok { $obj->refresh_token('alias_audience') }
      qr/no audience for alias 'alias_audience'/,
      'expected exception';
  };

  subtest "refresh_token() without stored refresh token" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok { $obj->refresh_token() }
      qr/no refresh token has been stored/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error');
  };
}

sub test_refresh_token_ok {
  subtest "refresh_token() with all tokens" => sub {

    # Given
    my $obj = build_object(token_response => {id_token      => 'my_id_token',
                                              access_token  => 'my_access_token',
                                              refresh_token => 'my_refresh_token',
                                              token_type    => 'my_token_type',
                                              expires_in    => 3600,
                                              scope         => 'openid scope'});
    my %access_token = (
      token => 'my_old_access_token',
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_old_refresh_token');
    my %identity = (
      subject => 'my_subject',
      token   => 'my_old_id_token',
      claims => {
        nonce => 'a1370',
      },
    );
    store_identity($obj, \%identity);

    # When
    my $access_token = $obj->refresh_token();

    # Then
    my %expected_stored_identity = (
      subject    => 'my_subject',
      token      => 'my_id_token',
      expires_at => 1111111,
      claims     => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        roles => [qw/role1 role2 role3/],
      },
    );
    cmp_deeply(get_identity($obj),
               \%expected_stored_identity,
               'expected stored identity');
    my $expected_stored_access_token = {
      expires_at => re('^\d+$'),
      token      => 'my_access_token',
      token_type => 'my_token_type',
      scopes     => [qw/openid scope/],
    };
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token,
               noclass($expected_stored_access_token),
               'expected result');
    cmp_deeply(get_access_token($obj),
               $expected_stored_access_token,
               'expected stored access token');
    cmp_deeply(get_refresh_token($obj),
               'my_refresh_token',
               'expected stored refresh token');
    cmp_deeply([ $obj->client->next_call(6) ],
               [ 'get_token', [ $obj->client, grant_type    => 'refresh_token',
                                              refresh_token => 'my_old_refresh_token' ] ],
               'expected call to client->get_token');
    cmp_deeply([ $obj->client->next_call(5) ],
               [ 'verify_token', [ $obj->client, token => 'my_id_token',
                                                 expected_audience => 'my_id',
                                                 expected_nonce    => 'a1370'] ],
               'expected call to client->verify_token');
  };

  subtest "refresh_token() with only access token" => sub {

    # Given
    my $obj = build_object(
      config => { refresh_scope => 'custom scope' }
    );
    my %access_token = (
      token => 'my_old_access_token',
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_old_refresh_token');

    # When
    my $access_token = $obj->refresh_token();

    # Then
    my $expected_stored_access_token = {
      expires_at => re('^\d+$'),
      token      => 'my_access_token',
      token_type => 'my_token_type',
      scopes     => [qw/scope/],
    };
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token,
               noclass($expected_stored_access_token),
               'expected result');
    cmp_deeply(get_access_token($obj),
               $expected_stored_access_token,
               'expected stored access token');
    cmp_deeply(get_refresh_token($obj),
               'my_refresh_token',
               'expected stored refresh token');
    cmp_deeply(get_identity($obj),
               undef,
               'no stored identity');
    cmp_deeply([ $obj->client->next_call(6) ],
               [ 'get_token', [ $obj->client, grant_type    => 'refresh_token',
                                              refresh_token => 'my_old_refresh_token',
                                              refresh_scope => 'custom scope' ] ],
               'expected call to client->get_token');
  };

  subtest "refresh_token() for other audience" => sub {

    # Given
    my $obj = build_object(config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} },
                                       refresh_scope  => 'custom scope' });
    my %audience_access_token = (
      token => 'my_old_audience_access_token',
    );
    store_access_token($obj, \%audience_access_token, 'my_audience');
    store_refresh_token($obj, 'my_old_audience_refresh_token', 'my_audience');

    # When
    my $access_token = $obj->refresh_token('my_audience_alias');

    # Then
    my $expected_stored_access_token = {
      expires_at => re('^\d+$'),
      token      => 'my_access_token',
      token_type => 'my_token_type',
      scopes     => [qw/scope/],
    };
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token,
               noclass($expected_stored_access_token),
               'expected result');
    cmp_deeply(get_access_token($obj, 'my_audience'),
               $expected_stored_access_token,
               'expected stored access token');
    cmp_deeply(get_refresh_token($obj, 'my_audience'),
               'my_refresh_token',
               'expected stored refresh token');
    cmp_deeply(get_identity($obj),
               undef,
               'no stored identity');
    cmp_deeply([ $obj->client->next_call(5) ],
               [ 'get_token', [ $obj->client, grant_type    => 'refresh_token',
                                              refresh_token => 'my_old_audience_refresh_token' ] ],
               'expected call to client->get_token');
  };

  subtest "refresh_token() with only ID token" => sub {

    # Given
    my $obj = build_object(token_response => {id_token      => 'my_id_token',
                                              refresh_token => 'my_refresh_token'});
    store_refresh_token($obj, 'my_old_refresh_token');
    my %identity = (
      subject => 'my_subject',
      token   => 'my_old_id_token',
      claims => {
        nonce => 'b4632',
      },
    );
    store_identity($obj, \%identity);

    # When
    my $access_token = $obj->refresh_token();

    # Then
    my %expected_stored_identity = (
      subject    => 'my_subject',
      token      => 'my_id_token',
      expires_at => 1111111,
      claims     => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        roles => [qw/role1 role2 role3/],
      },
    );
    cmp_deeply(get_identity($obj),
               \%expected_stored_identity,
               'expected stored identity');
    cmp_deeply(get_refresh_token($obj),
               'my_refresh_token',
               'expected stored refresh token');
    cmp_deeply($access_token,
               undef,
               'no access token');
    cmp_deeply(get_access_token($obj),
               undef,
               'no stored access token');
    cmp_deeply([ $obj->client->next_call(6) ],
               [ 'get_token', [ $obj->client, grant_type    => 'refresh_token',
                                              refresh_token => 'my_old_refresh_token' ] ],
               'expected call to client->get_token');
    cmp_deeply([ $obj->client->next_call(5) ],
               [ 'verify_token', [ $obj->client, token => 'my_id_token',
                                                 expected_audience => 'my_id',
                                                 expected_nonce    => 'b4632'] ],
               'expected call to client->verify_token');
  };
}

sub test_exchange_token_with_exceptions {
  subtest "exchange_token() without configured audience alias" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok { $obj->exchange_token('my_audience_alias') }
      qr/no audience for alias 'my_audience_alias'/,
      'expected exception';
  };

  subtest "exchange_token() without access token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );

    # When - Then
    throws_ok { $obj->exchange_token('my_audience_alias') }
      qr/no access token has been stored/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error');
  };
}

sub test_exchange_token_ok {
  subtest "exchange_token() ok" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');

    # When
    my $exchanged_access_token = $obj->exchange_token('my_audience_alias');

    # Then
    isa_ok($exchanged_access_token, 'OIDC::Client::AccessToken');
    my $expected_exchanged_access_token = {
      expires_at => re('^\d+$'),
      token      => 'my_exchanged_access_token',
      token_type => 'my_exchanged_token_type',
      scopes     => [qw/scope2/],
    };
    cmp_deeply($exchanged_access_token,
               noclass($expected_exchanged_access_token),
               'expected exchanged access token');
    cmp_deeply(get_access_token($obj, 'my_audience'),
               $expected_exchanged_access_token,
               'expected stored access token');
    cmp_deeply(get_refresh_token($obj, 'my_audience'),
               'my_exchanged_refresh_token',
               'expected stored refresh token');
    cmp_deeply([ $obj->client->next_call(6) ],
               [ 'exchange_token', [ $obj->client, token    => 'my_access_token',
                                                   audience => 'my_audience' ] ],
               'expected call to client->exchange_token');
  };
}

sub test_verify_token_with_exceptions {
  subtest "verify_token() without authorization header" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok { $obj->verify_token() }
      qr/no token in authorization header/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error');
  };

  subtest "verify_token() without expected type in authorization header" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'abcd123' }
    );

    # When - Then
    throws_ok { $obj->verify_token() }
      qr/no token in authorization header/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error');
  };
}

sub test_verify_token_ok {
  subtest "verify_token() token is stored in session" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd123' }
    );

    # When
    my $access_token = $obj->verify_token();

    # Then
    my %expected_access_token = (
      token      => 'abcd123',
      expires_at => 1111111,
      claims => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        roles => [qw/role1 role2 role3/],
      },
    );
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token,
               noclass(\%expected_access_token),
               'expected result');
    cmp_deeply(get_access_token($obj),
               \%expected_access_token,
               'expected stored access token');
    cmp_deeply([ $obj->client->next_call() ],
               [ 'default_token_type', [ $obj->client ] ],
               'expected call to client->default_token_type');
    cmp_deeply([ $obj->client->next_call() ],
               [ 'verify_token', [ $obj->client, token => 'abcd123' ] ],
               'expected call to client->verify_token');
  };

  subtest "verify_token() token is stored in stash" => sub {

    # Given
    my $obj = build_object(
      config          => { store_mode => 'stash' },
      request_headers => { Authorization => 'Bearer ABC2' },
    );

    # When
    my $access_token = $obj->verify_token();

    # Then
    my %expected_access_token = (
      token         => 'ABC2',
      expires_at    => 1111111,
      claims => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        roles => [qw/role1 role2 role3/],
      },
    );
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token,
               noclass(\%expected_access_token),
               'expected result');
    cmp_deeply(get_access_token($obj),
               undef,
               'not stored in session');
    cmp_deeply(get_access_token($obj, undef, 'stash'),
               \%expected_access_token,
               'stored in stash');
  };

  subtest "verify_token() with scope claim" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd123' },
      claims          => { iss => 'my_issuer',
                           exp => 1111111,
                           aud => 'my_id',
                           sub => 'my_subject',
                           scp => [qw/scope1 scope2 scope3/] },
    );

    # When
    my $access_token = $obj->verify_token();

    # Then
    my %expected_access_token = (
      token         => 'abcd123',
      expires_at    => 1111111,
      scopes        => [qw/scope1 scope2 scope3/],
      claims => {
        iss   => 'my_issuer',
        exp   => 1111111,
        aud   => 'my_id',
        sub   => 'my_subject',
        scp => [qw/scope1 scope2 scope3/],
      },
    );
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token,
               noclass(\%expected_access_token),
               'expected result');
    cmp_deeply(get_access_token($obj),
               \%expected_access_token,
               'expected stored access token');
  };

  subtest "verify_token() with mocked access token" => sub {

    my %mocked_access_token = (token  => 'my_mocked_token',
                               scopes => [qw/scope1 scope2/],
                               claims => {
                                 sub => 'my_mocked_subject',
                               });

    # Given
    my $obj = build_object(
      config     => { mocked_access_token => \%mocked_access_token },
      attributes => { base_url => 'http://localhost:3000' },
    );

    # When
    my $access_token = $obj->verify_token();

    # Then
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token, noclass(\%mocked_access_token),
               'expected result');
  };

  subtest "verify_token() with mocked claims but not in local environment" => sub {

    my %mocked_access_token = (token  => 'my_mocked_token',
                               scopes => [qw/scope1 scope2/],
                               claims => {
                                 sub => 'my_mocked_subject',
                               });

    # Given
    my $obj = build_object(
      config          => { mocked_access_token => \%mocked_access_token },
      attributes      => { base_url => 'http://my-app' },
      request_headers => { Authorization => 'bearer abcd1234' }
    );

    # When
    my $access_token = $obj->verify_token();

    # Then
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token, noclass(superhashof({token => 'abcd1234'})),
               'expected result');
  };
}

sub test_get_token_from_authorization_header {
  subtest "get_token_from_authorization_header() with token" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd12' }
    );

    # When
    my $token = $obj->get_token_from_authorization_header();

    # Then
    is($token, 'abcd12',
       'expected token')
  };

  subtest "get_token_from_authorization_header() without token" => sub {

    # Given
    my $obj = build_object(
      request_headers => {}
    );

    # When
    my $token = $obj->get_token_from_authorization_header();

    # Then
    is($token, undef,
       'no token : returns undef')
  };
}

sub test_get_userinfo {
  subtest "get_userinfo()" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token);

    # When
    my $userinfo = $obj->get_userinfo();

    # Then
    is($userinfo->{sub}, 'DOEJ',
       'expected subject');

    cmp_deeply([ $obj->client->next_call(5) ],
               [ 'get_userinfo', [ $obj->client, access_token => 'my_access_token', token_type => undef ] ],
               'expected call to client->get_userinfo');
  };

  subtest "get_userinfo() with mocked userinfo" => sub {

    my %mocked_userinfo = (lastName => 'my_mocked_lastname');

    # Given
    my $obj = build_object(
      config     => { mocked_userinfo => \%mocked_userinfo },
      attributes => { base_url => 'http://localhost:3000' },
    );

    # When
    my $userinfo = $obj->get_userinfo();

    # Then
    cmp_deeply($userinfo, \%mocked_userinfo,
               'expected result');
  };

  subtest "get_userinfo() with mocked userinfo but not in local environment" => sub {

    my %mocked_userinfo = (lastName => 'my_mocked_lastname');

    # Given
    my $obj = build_object(
      config     => { mocked_userinfo => \%mocked_userinfo },
      attributes => { base_url => 'http://my-app' },
    );
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token);

    # When
    my $userinfo = $obj->get_userinfo();

    # Then
    is($userinfo->{sub}, 'DOEJ',
       'expected subject');
  };
}

sub test_build_user_from_userinfo {
  subtest "build_user_from_userinfo()" => sub {

    # Prepare
    my %claim_mapping = (
      login     => 'sub',
      lastname  => 'lastName',
      firstname => 'firstName',
      email     => 'email',
      roles     => 'roles',
    );
    my %userinfo = (
      sub       => 'DOEJ',
      firstName => 'John',
      lastName  => 'Doe',
      roles     => [qw/app.role1 app.role2 app.role3/],
    );

    # Given
    my $obj = build_object(
      config   => { claim_mapping => \%claim_mapping,
                    role_prefix   => 'app.' },
      userinfo => \%userinfo,
    );
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token);

    # When
    my $user = $obj->build_user_from_userinfo();

    # Then
    my $expected_user = OIDC::Client::User->new(
      login       => 'DOEJ',
      lastname    => 'Doe',
      firstname   => 'John',
      roles       => [qw/app.role1 app.role2 app.role3/],
      role_prefix => 'app.',
    );
    cmp_deeply($user, $expected_user,
               'expected user');
  };
}

sub test_build_user_from_claims {
  subtest "test_build_user_from_claims()" => sub {

    # Prepare
    my %claim_mapping = (
      login     => 'sub',
      lastname  => 'lastName',
      firstname => 'firstName',
      email     => 'email',
      roles     => 'roles',
    );
    my %claims = (
      sub         => 'DOEJ',
      firstName   => 'John',
      lastName    => 'Doe',
      email       => 'john.doe@mydomain.com',
      roles       => [qw/app.role1 app.role2/],
      nationality => 'USA',
    );

    # Given
    my $obj = build_object(
      config   => { claim_mapping => \%claim_mapping,
                    role_prefix   => 'app.' },
    );
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token);

    # When
    my $user = $obj->build_user_from_claims(\%claims);

    # Then
    my $expected_user = OIDC::Client::User->new(
      login       => 'DOEJ',
      lastname    => 'Doe',
      firstname   => 'John',
      email       => 'john.doe@mydomain.com',
      roles       => [qw/app.role1 app.role2/],
      role_prefix => 'app.',
    );
    cmp_deeply($user, $expected_user,
               'expected user');
  };
}

sub test_build_user_from_identity {
  subtest "build_user_from_identity()" => sub {

    # Given
    my %claim_mapping = (
      login     => 'sub',
      lastname  => 'lastName',
      firstname => 'firstName',
      email     => 'email',
      roles     => 'roles',
    );
    my $obj = build_object(
      config  => { claim_mapping => \%claim_mapping },
    );
    my %identity = (
      subject    => 'DOEJ',
      token      => 'ID token',
      expires_at => 888,
      claims     => {
        sub       => 'DOEJ',
        lastName  => 'Doe',
        firstName => 'John',
      },
    );
    store_identity($obj, \%identity);

    # When
    my $user = $obj->build_user_from_identity();

    # Then
    my $expected_user = OIDC::Client::User->new(
      login       => 'DOEJ',
      lastname    => 'Doe',
      firstname   => 'John',
      role_prefix => '',
    );
    cmp_deeply($user, $expected_user,
               'expected user');
  };
}

sub test_build_api_useragent {
  subtest "build_api_useragent() with valid access token for audience" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %access_token = (
      token      => 'my_audience_access_token',
      token_type => 'my_audience_token_type',
    );
    store_access_token($obj, \%access_token, 'my_audience');

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
  };

  subtest "build_api_useragent() without access token for audience" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %access_token = (
      token      => 'my_access_token',
      expires_at => 11
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
  };

  subtest "build_api_useragent() without valid access token for audience" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
    );
    my %audience_access_token = (
      token      => 'my_audience_access_token',
      token_type => 'my_audience_token_type',
      expires_at => 11,
    );
    store_access_token($obj, \%audience_access_token, 'my_audience');
    store_refresh_token($obj, 'my_audience_refresh_token', 'my_audience');
    my %access_token = (
      token         => 'my_a_token',
      refresh_token => 'my_r_token',
    );
    store_access_token($obj, \%access_token);

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
  };

  subtest "build_api_useragent() with error while refreshing access token for audience" => sub {
    $log->clear();

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %audience_access_token = (
      token      => 'my_audience_access_token',
      token_type => 'my_audience_token_type',
      expires_at => 11,
    );
    store_access_token($obj, \%audience_access_token, 'my_audience');
    store_refresh_token($obj, 'my_audience_refresh_token', 'my_audience');
    my %access_token = (
      token         => 'my_access_token',
      refresh_token => 'my_refresh_token',
    );
    store_access_token($obj, \%access_token);
    $obj->client->mock('get_token', sub { die 'to have an error while refreshing token' });

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');

    cmp_deeply($log->msgs->[2],
               superhashof({
                 message => re(q{OIDC: error refreshing access token for audience 'my_audience'}),
               }),
               'expected log');
  };

  subtest "build_api_useragent() without valid access token for audience and cannot exchange token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
    );
    my %access_token = (
      token      => 'my_access_token',
      expires_at => 11,
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');
    $obj->client->mock(exchange_token => sub { die 'to have an error while exchanging token' });

    # When - Then
    throws_ok { $obj->build_api_useragent('my_audience_alias') }
      qr/error while exchanging token/,
      'expected exception';
  };

  subtest "build_api_useragent() for current audience" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_access_token_for_current_audience',
      token_type => 'my_token_type_for_current_audience',
    );
    store_access_token($obj, \%access_token);

    # When
    my $ua = $obj->build_api_useragent();

    # Then
    isa_ok($ua, 'Mojo::UserAgent');
  };
}

sub test_redirect_to_logout_with_id_token {
  subtest "redirect_to_logout() with id token" => sub {

    # Given
    my $obj = build_object(attributes => { logout_redirect_uri => 'my_logout_redirect_uri' });
    my %identity = (subject    => 'my_subject',
                    claims     => {},
                    token      => 'my_id_token',
                    expires_at => 777);
    store_identity($obj, \%identity);

    # When
    $obj->redirect_to_logout(
      extra_params       => { param => 'param' },
      target_url         => 'my_target_url',
      other_state_params => ['my_state'],
    );

    # Then
    my ($state, $logout_data) = get_logout_data($obj);
    cmp_deeply($state, re('^my_state,[\w-]{36,36}$'),
               'expected state');
    cmp_deeply($logout_data,
               { provider   => 'my_provider',
                 target_url => 'my_target_url' },
               'expected oidc_logout session data');

    is($obj->redirect->(), 'my_logout_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call(4) ],
               [ 'logout_url', bag($obj->client, id_token                 => 'my_id_token',
                                                 post_logout_redirect_uri => 'my_logout_redirect_uri',
                                                 state                    => $state,
                                                 extra_params             => { param => 'param' }) ],
               'expected call to client');
  };
}

sub test_redirect_to_logout_without_id_token {
  subtest "redirect_to_logout() without id token" => sub {

    # Given
    my $obj = build_object(attributes => { logout_redirect_uri => 'my_logout_redirect_uri' });

    # When
    $obj->redirect_to_logout(
      with_id_token            => 0,
      post_logout_redirect_uri => 'my_personal_logout_redirect_uri',
    );

    # Then
    my ($state, $logout_data) = get_logout_data($obj);
    cmp_deeply($state, re('^[\w-]{36,36}$'),
               'expected state');
    cmp_deeply($logout_data,
               { provider   => 'my_provider',
                 target_url => undef },
               'expected oidc_logout session data');

    is($obj->redirect->(), 'my_logout_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call() ],
               [ 'logout_url', bag($obj->client, post_logout_redirect_uri => 'my_personal_logout_redirect_uri',
                                                 state                    => $state) ],
               'expected call to client');
  };
}

sub test_get_valid_access_token_with_exceptions {
  subtest "get_valid_access_token() without configured audience alias" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok { $obj->get_valid_access_token('my_audience_alias') }
      qr/no audience for alias 'my_audience_alias'/,
      'expected exception';
  };

  subtest "get_valid_access_token() with expired access token and no refresh token" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_access_token',
      expires_at => 1234,
    );
    store_access_token($obj, \%access_token);

    # When - Then
    throws_ok { $obj->get_valid_access_token() }
      qr/no refresh token has been stored/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error');
  };

  subtest "get_valid_access_token() with expired exchanged token and no refresh token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
    );
    my %access_token = (
      token      => 'my_access_token',
      expires_at => 12,
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');
    my %audience_access_token = (
      token      => 'my_old_audience_access_token',
      expires_at => 12,
    );
    store_access_token($obj, \%audience_access_token, 'my_audience');

    # When
    my $access_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    is($access_token->token, 'my_exchanged_access_token',
       'token is exchanged');
  };
}

sub test_get_valid_access_token {

  subtest "get_valid_access_token() with expired access token" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_stored_token',
      expires_at => 1234,
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');

    # When
    my $access_token = $obj->get_valid_access_token();

    # Then
    is($access_token->token, 'my_access_token',
       'expected token');
  };

  subtest "get_valid_access_token() without expiration time" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_stored_token',
      expires_at => undef,
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');

    # When
    my $access_token = $obj->get_valid_access_token();

    # Then
    is($access_token->token, 'my_stored_token',
       'expected token');
  };

  subtest "get_valid_access_token() with unexpired token" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_stored_token',
      expires_at => time + 30,
    );
    store_access_token($obj, \%access_token);

    # When
    my $access_token = $obj->get_valid_access_token();

    # Then
    is($access_token->token, 'my_stored_token',
       'expected token');
  };
}

sub test_get_valid_access_token_for_audience {
  subtest "get_valid_access_token() with expired exchanged token when including leeway" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias    => { my_audience_alias => {audience => 'my_audience'} },
                  expiration_leeway => 60 },
    );
    my %access_token = (
      token      => 'my_old_access_token',
      expires_at => time + 30,
    );
    store_access_token($obj, \%access_token, 'my_audience');
    store_refresh_token($obj, 'my_old_refresh_token', 'my_audience');

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    is($exchanged_token->token, 'my_access_token',
       'expected token');
  };

  subtest "get_valid_access_token() with unexpired exchanged token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %access_token = (
      token      => 'my_exchanged_token',
      expires_at => time + 30,
    );
    store_access_token($obj, \%access_token, 'my_audience');

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    is($exchanged_token->token, 'my_exchanged_token',
       'expected token');
  };

  subtest "get_valid_access_token() without stored exchanged token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %access_token = (
      token => 'my_token',
    );
    store_access_token($obj, \%access_token);
    store_refresh_token($obj, 'my_refresh_token');

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    is($exchanged_token->token, 'my_exchanged_access_token',
       'expected token');
  };

  subtest "get_valid_access_token() with mocked token" => sub {

    my %mocked_access_token = (token  => 'my_mocked_token',
                               scopes => [qw/scope1/]);

    # Given
    my $obj = build_object(
      config     => { mocked_access_token  => \%mocked_access_token,
                      audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      attributes => { base_url => 'http://localhost:3000' },
    );

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    isa_ok($exchanged_token, 'OIDC::Client::AccessToken');
    cmp_deeply($exchanged_token, noclass(\%mocked_access_token),
               'expected result');
  };

  subtest "get_valid_access_token() with mocked token but not in local environment" => sub {

    my %mocked_access_token = (token  => 'my_mocked_token',
                               scopes => [qw/scope1/]);

    # Given
    my $obj = build_object(
      config     => { mocked_access_token  => \%mocked_access_token,
                      audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      attributes => { base_url => 'http://my-app' },
    );
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token, 'my_audience');

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    cmp_deeply($exchanged_token->token, 'my_access_token',
               'expected token');
  };
}

sub test_get_stored_access_token {
  subtest "get_stored_access_token() with unexpired token" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_stored_token',
      expires_at => time + 30,
    );
    store_access_token($obj, \%access_token);

    # When
    my $access_token = $obj->get_stored_access_token();

    # Then
    is($access_token->token, 'my_stored_token',
       'expected token');
  };

  subtest "get_stored_access_token() with expired access token" => sub {

    # Given
    my $obj = build_object();
    my %access_token = (
      token      => 'my_stored_token',
      expires_at => 1234,
    );
    store_access_token($obj, \%access_token);

    # When
    my $access_token = $obj->get_stored_access_token();

    # Then
    is($access_token->token, 'my_stored_token',
       'expected token');
  };

  subtest "get_stored_access_token() with mocked token" => sub {

    my %mocked_access_token = (token  => 'my_mocked_token',
                               scopes => [qw/scope1/],
                               claims => {
                                 sub => 'my_mocked_subject',
                               });

    # Given
    my $obj = build_object(
      config     => { mocked_access_token  => \%mocked_access_token },
      attributes => { base_url => 'http://localhost:3000' },
    );

    # When
    my $access_token = $obj->get_stored_access_token();

    # Then
    isa_ok($access_token, 'OIDC::Client::AccessToken');
    cmp_deeply($access_token, noclass(\%mocked_access_token),
               'expected result');
  };

  subtest "get_stored_access_token() with mocked token but not in local environment" => sub {

    my %mocked_access_token = (token  => 'my_mocked_token',
                               scopes => [qw/scope1/],
                               claims => {
                                 sub => 'my_mocked_subject',
                               });

    # Given
    my $obj = build_object(
      config     => { mocked_access_token  => \%mocked_access_token },
      attributes => { base_url => 'http://my-app' },
    );
    my %access_token = (
      token => 'my_access_token',
    );
    store_access_token($obj, \%access_token);

    # When
    my $access_token = $obj->get_stored_access_token();

    # Then
    cmp_deeply($access_token->token, 'my_access_token',
               'expected token');
  };
}

sub test_get_valid_identity {
  subtest "get_valid_identity() without stored identity" => sub {

    # Given
    my $obj = build_object();

    # When
    my $result = $obj->get_valid_identity();

    # Then
    is($result, undef,
       'expected result');
  };

  subtest "get_valid_identity() with stored and valid identity" => sub {

    # Given
    my $obj = build_object();
    my %identity = (
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => undef
    );
    store_identity($obj, \%identity);

    # When
    my $valid_identity = $obj->get_valid_identity();

    # Then
    isa_ok($valid_identity, 'OIDC::Client::Identity');
    cmp_deeply($valid_identity, noclass(\%identity),
               'expected result');
  };

  subtest "get_valid_identity() with stored and expired identity" => sub {

    # Given
    my $obj = build_object();
    my %identity = (
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => 777,
    );
    store_identity($obj, \%identity);

    # When
    my $result = $obj->get_valid_identity();

    # Then
    cmp_deeply($result, undef,
               'expected result');
  };
}

sub test_get_stored_identity {
  subtest "test_get_stored_identity() without stored identity" => sub {

    # Given
    my $obj = build_object();

    # When
    my $result = $obj->get_stored_identity();

    # Then
    is($result, undef,
       'expected result');
  };

  subtest "test_get_stored_identity() with stored and valid identity" => sub {

    # Given
    my $obj = build_object();
    my %identity = (
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => undef,
    );
    store_identity($obj, \%identity);

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    isa_ok($stored_identity, 'OIDC::Client::Identity');
    cmp_deeply($stored_identity, noclass(\%identity),
               'expected result');
  };

  subtest "test_get_stored_identity() with stored and expired identity" => sub {

    # Given
    my $obj = build_object();
    my %identity = (
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => 777,
    );
    store_identity($obj, \%identity);

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    isa_ok($stored_identity, 'OIDC::Client::Identity');
    cmp_deeply($stored_identity, noclass(\%identity),
               'expected result');
  };

  subtest "get_stored_identity() with mocked identity" => sub {

    my %mocked_identity = (subject    => 'my_mocked_subject',
                           claims     => {},
                           token      => 'my_mocked_token',
                           expires_at => undef);

    # Given
    my $obj = build_object(
      config     => { mocked_identity => \%mocked_identity },
      attributes => { base_url => 'http://localhost:3002' },
    );

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    isa_ok($stored_identity, 'OIDC::Client::Identity');
    cmp_deeply($stored_identity, noclass(\%mocked_identity),
               'expected result');
  };

  subtest "get_stored_identity() with mocked identity but not in local environment" => sub {

    my %identity = (subject    => 'my_mocked_subject',
                    claims     => {},
                    token      => 'my_mocked_token',
                    expires_at => undef);

    # Given
    my $obj = build_object(
      config     => { mocked_identity => \%identity },
      attributes => { base_url => 'http://my-app' },
    );

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    cmp_deeply($stored_identity, undef,
               'expected result');
  };
}

sub test_store_access_token {
  subtest "store_access_token() with audience_alias" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );

    # When
    my $access_token = OIDC::Client::AccessToken->new(
      token      => 'my_token',
      expires_at => 7777,
      token_type => 'my_token_type',
      scopes     => [qw/scope/],
    );
    $obj->store_access_token($access_token, 'my_audience_alias');

    # Then
    my $expected_stored_access_token = {
      token      => 'my_token',
      expires_at => 7777,
      token_type => 'my_token_type',
      scopes     => [qw/scope/],
    };
    cmp_deeply(get_access_token($obj, 'my_audience'),
               $expected_stored_access_token,
               'expected stored data');
  };

  subtest "store_access_token() without audience_alias" => sub {

    # Given
    my $obj = build_object();

    # When
    my $access_token = OIDC::Client::AccessToken->new(
      token      => 'my_token',
      expires_at => 8888,
      token_type => 'my_token_type',
      scopes     => [qw/scope1 scope2/],
    );
    $obj->store_access_token($access_token);

    # Then
    my $expected_stored_access_token = {
      token      => 'my_token',
      expires_at => 8888,
      token_type => 'my_token_type',
      scopes     => [qw/scope1 scope2/],
    };
    cmp_deeply(get_access_token($obj),
               $expected_stored_access_token,
               'expected stored data');
  };
}

sub test_store_refresh_token {
  subtest "store_refresh_token() with audience_alias" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my $refresh_token = 'my_audience_refresh_token';

    # When
    $obj->store_refresh_token($refresh_token, 'my_audience_alias');

    # Then
    my $expected_stored_refresh_token = 'my_audience_refresh_token';
    cmp_deeply(get_refresh_token($obj, 'my_audience'),
               $expected_stored_refresh_token,
               'expected stored refresh token');
  };

  subtest "store_refresh_token() without audience_alias" => sub {

    # Given
    my $obj = build_object();
    my $refresh_token = 'my_refresh_token';

    # When
    $obj->store_refresh_token($refresh_token);

    # Then
    my $expected_stored_refresh_token = 'my_refresh_token';
    cmp_deeply(get_refresh_token($obj),
               $expected_stored_refresh_token,
               'expected stored refresh token');
  };
}

sub test_delete_stored_data {
  subtest "delete_stored_data()" => sub {

    # Given
    my $obj = build_object();
    my %identity = (
      subject    => 'my_subject',
      claims     => {},
      token      => 'my_id_token',
      expires_at => 777,
    );
    store_identity($obj, \%identity);
    my %access_token = (
      token      => 'my_access_token',
      expires_at => 11,
    );
    store_access_token($obj, \%access_token);

    # When
    $obj->delete_stored_data();

    # Then
    is(get_identity($obj),
       undef,
       'identity has been deleted');
    is(get_access_token($obj),
       undef,
       'access token has been deleted');
  };
}

sub build_object {
  my (%params) = @_;

  my %default_claim_mapping = (
    login => 'sub',
    roles => 'roles',
  );
  my %default_userinfo = (
    sub   => 'DOEJ',
    roles => [qw/role1 role2 role3/],
  );
  my %default_claims = (
    iss   => 'my_issuer',
    exp   => 1111111,
    aud   => 'my_id',
    sub   => 'my_subject',
    roles => [qw/role1 role2 role3/],
  );
  my %default_token_response = (
    access_token  => 'my_access_token',
    refresh_token => 'my_refresh_token',
    token_type    => 'my_token_type',
    expires_in    => 3600,
    scope         => ' scope ',
  );
  my %exchanged_token = (
    access_token  => 'my_exchanged_access_token',
    refresh_token => 'my_exchanged_refresh_token',
    token_type    => 'my_exchanged_token_type',
    expires_in    => 3600,
    scope         => 'scope2',
  );
  my %config = %{ $params{config} || {} };

  my $mock_client = Test::MockObject->new();
  $mock_client->set_isa('OIDC::Client');
  $mock_client->mock(config              => sub { \%config });
  $mock_client->mock(auth_url            => sub { 'my_auth_url' });
  $mock_client->mock(logout_url          => sub { 'my_logout_url' });
  $mock_client->mock(id                  => sub { 'my_id' });
  $mock_client->mock(audience            => sub { $config{audience} || 'my_id' });
  $mock_client->mock(provider            => sub { 'my_provider' });
  $mock_client->mock(verify_token        => sub { $params{claims} || \%default_claims });
  $mock_client->mock(claim_mapping       => sub { $config{claim_mapping} || \%default_claim_mapping });
  $mock_client->mock(role_prefix         => sub { $config{role_prefix} || ''});
  $mock_client->mock(get_token           => sub { OIDC::Client::TokenResponse->new($params{token_response} || \%default_token_response) });
  $mock_client->mock(exchange_token      => sub { OIDC::Client::TokenResponse->new(%exchanged_token) });
  $mock_client->mock(build_api_useragent => sub { Mojo::UserAgent->new(); });
  $mock_client->mock(has_expired         => sub { $params{has_expired} // 0 });
  $mock_client->mock(get_userinfo        => sub { $params{userinfo} || \%default_userinfo });
  $mock_client->mock(default_token_type  => sub { 'Bearer' });
  $mock_client->mock(get_claim_value => sub {
    my ($self, %params) = @_;
    return $params{claims}->{$self->claim_mapping->{$params{name}}};
  });
  $mock_client->mock(get_audience_for_alias => sub {
    my (undef, $alias) = @_;
    return $params{config}->{audience_alias}{$alias}{audience};
  });

  my $redirect;

  return $class->new(
    log             => $log,
    request_params  => $params{request_params} || {},
    request_headers => $params{request_headers} || {},
    session         => {},
    stash           => {},
    redirect        => sub { if ($_[0]) { $redirect = $_[0]; return; }
                             else { return $redirect } },
    client          => $mock_client,
    base_url        => 'http://my-app/',
    current_url     => '/current-url',
    %{$params{attributes} || {}},
  );
}

sub store_identity {
  my ($obj, $identity, $store_mode) = @_;

  my $store = get_store($obj, $store_mode);
  $store->{oidc}{provider}{my_provider}{audience}{my_id}{identity} = $identity;
}

sub get_identity {
  my ($obj, $store_mode) = @_;

  my $store = get_store($obj, $store_mode);
  return $store->{oidc}{provider}{my_provider}{audience}{my_id}{identity};
}

sub store_access_token {
  my ($obj, $access_token, $audience, $store_mode) = @_;

  my $store = get_store($obj, $store_mode);
  $store->{oidc}{provider}{my_provider}{audience}{$audience || 'my_id'}{access_token} = $access_token;
}

sub get_access_token {
  my ($obj, $audience, $store_mode) = @_;

  my $store = get_store($obj, $store_mode);
  return $store->{oidc}{provider}{my_provider}{audience}{$audience || 'my_id'}{access_token};
}

sub store_refresh_token {
  my ($obj, $refresh_token, $audience, $store_mode) = @_;

  my $store = get_store($obj, $store_mode);
  $store->{oidc}{provider}{my_provider}{audience}{$audience || 'my_id'}{refresh_token} = $refresh_token;
}

sub get_refresh_token {
  my ($obj, $audience, $store_mode) = @_;

  my $store = get_store($obj, $store_mode);
  return $store->{oidc}{provider}{my_provider}{audience}{$audience || 'my_id'}{refresh_token};
}

sub get_store {
  my ($obj, $store_mode) = @_;
  $store_mode ||= 'session';

  my $store = $store_mode eq 'session' ? $obj->session
                                       : $obj->stash;
}

sub get_auth_data {
  my ($obj) = @_;

  my @states = keys %{$obj->session->{oidc_auth}};
  if (@states == 1) {
    my $state = $states[0];
    my $auth_data = $obj->session->{oidc_auth}{$state};
    return ($state, $auth_data);
  }
  elsif (@states == 0) {
    return ();
  }
  else {
    die q{should have maximum one state in 'oidc_auth' hashref};
  }
}

sub set_auth_data {
  my ($obj, $state, $data) = @_;

  $obj->session->{oidc_auth}{$state} = $data;
}

sub get_logout_data {
  my ($obj) = @_;

  my @states = keys %{$obj->session->{oidc_logout}};
  if (@states == 1) {
    my $state = $states[0];
    my $auth_data = $obj->session->{oidc_logout}{$state};
    return ($state, $auth_data);
  }
  elsif (@states == 0) {
    return ();
  }
  else {
    die q{should have maximum one state in 'oidc_logout' hashref};
  }
}

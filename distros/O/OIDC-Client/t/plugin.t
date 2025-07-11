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
    cmp_deeply($obj->get_flash->('oidc_state'), re('^state_param1,state_param2,[\w-]{36,36}$'),
       'expected oidc_state flash');

    is($obj->get_flash->('oidc_provider'), 'my_provider',
       'expected oidc_provider flash');

    is($obj->get_flash->('oidc_target_url'), 'my_target_url',
       'expected oidc_target_url flash');

    is($obj->redirect->(), 'my_auth_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call() ],
               [ 'auth_url', bag($obj->client, nonce        => re('^[\w-]{36,36}$'),
                                               state        => re('^state_param1,state_param2,[\w-]+$'),
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
    cmp_deeply($obj->get_flash->('oidc_nonce'), re('^[\w-]{36,36}$'),
       'expected oidc_state flash');

    cmp_deeply($obj->get_flash->('oidc_state'), re('^[\w-]{36,36}$'),
       'expected oidc_state flash');

    isnt($obj->get_flash->('oidc_nonce'), $obj->get_flash->('oidc_state'),
       'oidc_nonce and oidc_state have different values');

    is($obj->get_flash->('oidc_provider'), 'my_provider',
       'expected oidc_provider flash');

    is($obj->get_flash->('oidc_target_url'), '/current-url',
       'expected oidc_target_url flash');

    is($obj->redirect->(), 'my_auth_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call() ],
               [ 'auth_url', bag($obj->client, nonce => re('^[\w-]{36,36}$'),
                                               state => re('^[\w-]{36,36}$')) ],
               'expected call to client');
  };
}

sub test_get_token_with_provider_error {
  subtest "get_token() with provider error" => sub {

    # Given
    my $obj = build_object(request_params => {error => 'error from provider'});

    # When - Then
    throws_ok {
      $obj->get_token();
    } qr/error from provider/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Provider');
  };
}

sub test_get_token_with_invalid_state_parameter {
  subtest "get_token() without state parameter/flash" => sub {

    # Given
    my $obj = build_object(request_params => {},
                           flash          => {});

    # When - Then
    throws_ok {
      $obj->get_token();
    } qr/invalid state parameter/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Authentication');
  };

  subtest "get_token() without state parameter" => sub {

    # Given
    my $obj = build_object(request_params => {},
                           flash          => {oidc_state => 'abc'});

    # When - Then
    throws_ok {
      $obj->get_token();
    } qr/got '' but expected 'abc'/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Authentication');
  };

  subtest "get_token() with state parameter different from state in flash" => sub {

    # Given
    my $obj = build_object(request_params => {state      => 'aaa'},
                           flash          => {oidc_state => 'abc'});

    # When - Then
    throws_ok {
      $obj->get_token();
    } qr/got 'aaa' but expected 'abc'/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Authentication');
  };
}

sub test_get_token_ok {
  subtest "get_token() with all tokens" => sub {

    # Given
    my $obj = build_object(request_params => {code       => 'my_code',
                                              state      => 'abc'},
                           flash          => {oidc_nonce => 'my-nonce',
                                              oidc_state => 'abc'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    my %expected_stored_identity = (
      token      => 'my_id_token',
      subject    => 'my_subject',
      login      => 'my_subject',
      roles      => [qw/role1 role2 role3/],
      expires_at => 1111111,
    );
    cmp_deeply(
      $identity,
      \%expected_stored_identity,
      'expected returned identity'
    );
    cmp_deeply(
      get_stored_identity($obj),
      \%expected_stored_identity,
      'expected stored identity'
    );

    my %expected_stored_access_token = (
      expires_at    => re('^\d+$'),
      token         => 'my_access_token',
      refresh_token => 'my_refresh_token',
      token_type    => 'my_token_type',
    );
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_access_token,
      'expected stored access token'
    );
    cmp_deeply([ $obj->client->next_call() ],
               [ 'get_token', [ $obj->client, code         => 'my_code',
                                              redirect_uri => 'my_redirect_uri' ] ],
               'expected call to client->get_token');
    cmp_deeply([ $obj->client->next_call(2) ],
               [ 'verify_token', [ $obj->client, token             => 'my_id_token',
                                                 expected_audience => 'my_id',
                                                 expected_nonce    => 'my-nonce'] ],
               'expected call to client->verify_token');
  };

  subtest "get_token() with only ID token" => sub {

    # Given
    my $obj = build_object(request_params => {code       => 'my_code',
                                              state      => 'abc'},
                           flash          => {oidc_nonce => 'my-nonce',
                                              oidc_state => 'abc'},
                           token_response => {id_token   => 'my_id_token'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    my %expected_stored_identity = (
      token      => 'my_id_token',
      subject    => 'my_subject',
      login      => 'my_subject',
      roles      => [qw/role1 role2 role3/],
      expires_at => 1111111,
    );
    cmp_deeply(
      $identity,
      \%expected_stored_identity,
      'expected returned identity'
    );
    cmp_deeply(
      get_stored_identity($obj),
      \%expected_stored_identity,
      'expected stored identity'
    );

    cmp_deeply(
      get_stored_access_token($obj),
      undef,
      'no stored access token'
    );
  };

  subtest "get_token() - identity expires in configured number of seconds" => sub {

    # Given
    my $expires_in = 3600;
    my $obj = build_object(request_params => {code                => 'my_code',
                                              state               => 'abc'},
                           flash          => {oidc_nonce          => 'my-nonce',
                                              oidc_state          => 'abc'},
                           token_response => {id_token            => 'my_id_token'},
                           config         => {identity_expires_in => $expires_in});
    # When
    my $begin_time = time;
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    cmp_deeply(
      $identity->{expires_at},
      num($begin_time + $expires_in, 1),
      'expected expires_at'
    );
  };

  subtest "get_token() - no identity expiration" => sub {

    # Given
    my $obj = build_object(request_params => {code                => 'my_code',
                                              state               => 'abc'},
                           flash          => {oidc_nonce          => 'my-nonce',
                                              oidc_state          => 'abc'},
                           token_response => {id_token            => 'my_id_token'},
                           config         => {identity_expires_in => 0});
    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    ok(! exists $identity->{expires_at},
       'no expires_at');
  };

  subtest "get_token() with only access token" => sub {

    # Given
    my $obj = build_object(request_params => {code       => 'my_code',
                                              state      => 'abc'},
                           flash          => {oidc_nonce => 'my-nonce',
                                              oidc_state => 'abc'},
                           token_response => {access_token => 'my_access_token'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    cmp_deeply(
      $identity,
      undef,
      'no returned identity'
    );
    cmp_deeply(
      get_stored_identity($obj),
      undef,
      'no stored identity'
    );

    my %expected_stored_access_token = (
      token => 'my_access_token',
    );
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_access_token,
      'expected stored access token'
    );
  };

  subtest "get_token() with access token and refresh token" => sub {

    # Given
    my $obj = build_object(request_params => {code       => 'my_code',
                                              state      => 'abc'},
                           flash          => {oidc_nonce => 'my-nonce',
                                              oidc_state => 'abc'},
                           token_response => {access_token  => 'my_access_token',
                                              refresh_token => 'my_refresh_token'});

    # When
    my $identity = $obj->get_token(
      redirect_uri => 'my_redirect_uri',
    );

    # Then
    cmp_deeply(
      $identity,
      undef,
      'no returned identity'
    );
    cmp_deeply(
      get_stored_identity($obj),
      undef,
      'no stored identity'
    );

    my %expected_stored_access_token = (
      token         => 'my_access_token',
      refresh_token => 'my_refresh_token',
    );
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_access_token,
      'expected stored access token'
    );
  };
}

sub test_refresh_token_with_exceptions {
  subtest "refresh_token() with unknown_audience" => sub {

    # Given
    my $obj = build_object();
    $obj->client->mock('get_audience_for_alias', sub {});

    # When - Then
    throws_ok {
      $obj->refresh_token('alias_audience');
    } qr/no audience for alias 'alias_audience'/,
      'expected exception';
  };

  subtest "refresh_token() without stored access token" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok {
      $obj->refresh_token();
    } qr/no access token has been stored/,
      'expected exception';
  };

  subtest "refresh_token() without stored refresh token" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { refresh_token => undef }
    );

    # When - Then
    is($obj->refresh_token(), undef,
       'expected result');
  };
}

sub test_refresh_token_ok {
  subtest "refresh_token() ok" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { token         => 'my_old_access_token',
        refresh_token => 'my_old_refresh_token' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );

    # When
    $obj->refresh_token();

    # Then
    my %expected_stored_access_token = (
      expires_at    => re('^\d+$'),
      token         => 'my_access_token',
      refresh_token => 'my_refresh_token',
      token_type    => 'my_token_type',
    );
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_access_token,
      'expected stored access token'
    );
    cmp_deeply([ $obj->client->next_call(3) ],
               [ 'get_token', [ $obj->client, grant_type    => 'refresh_token',
                                              refresh_token => 'my_old_refresh_token' ] ],
               'expected call to client->get_token');
  };
}

sub test_exchange_token_with_exceptions {
  subtest "exchange_token() without configured audience alias" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok {
      $obj->exchange_token('my_audience_alias');
    } qr/no audience for alias 'my_audience_alias'/,
      'expected exception';
  };

  subtest "exchange_token() without access token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );

    # When - Then
    throws_ok {
      $obj->exchange_token('my_audience_alias');
    } qr/cannot retrieve a valid access token/,
      'expected exception';
    isa_ok($@, 'OIDC::Client::Error::Authentication');
  };
}

sub test_exchange_token_ok {
  subtest "exchange_token() ok" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );

    # When
    my $exchanged_token = $obj->exchange_token('my_audience_alias');

    # Then
    my %expected_exchanged_token = (
      expires_at    => re('^\d+$'),
      token         => 'my_exchanged_access_token',
      refresh_token => 'my_exchanged_refresh_token',
      token_type    => 'my_exchanged_token_type',
    );
    cmp_deeply(
      $exchanged_token,
      \%expected_exchanged_token,
      'expected exchanged token'
    );
    cmp_deeply(
      get_stored_access_token($obj, 'my_audience'),
      \%expected_exchanged_token,
      'expected stored access token'
    );
    cmp_deeply([ $obj->client->next_call(5) ],
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
    throws_ok {
      $obj->verify_token();
    } qr/no token in authorization header/,
      'expected exception';
  };

  subtest "verify_token() without expected type in authorization header" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'abcd123' }
    );

    # When - Then
    throws_ok {
      $obj->verify_token();
    } qr/no token in authorization header/,
      'expected exception';
  };
}

sub test_verify_token_ok {
  subtest "verify_token() token is stored in session" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd123' }
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    my %expected_claims = (
      iss   => 'my_issuer',
      exp   => 1111111,
      aud   => 'my_id',
      sub   => 'my_subject',
      roles => [qw/role1 role2 role3/],
    );
    my %expected_stored_token = (
      token      => 'abcd123',
      expires_at => 1111111,
      scopes     => [],
    );
    cmp_deeply($claims,
               \%expected_claims,
               'expected result');
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_token,
      'expected stored access token'
    );
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
      request_headers => { Authorization => 'Bearer ABC2' },
      store_mode      => 'stash',
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    my %expected_claims = (
      iss   => 'my_issuer',
      exp   => 1111111,
      aud   => 'my_id',
      sub   => 'my_subject',
      roles => [qw/role1 role2 role3/],
    );
    my %expected_stored_token = (
      token      => 'ABC2',
      expires_at => 1111111,
      scopes     => [],
    );
    cmp_deeply($claims,
               \%expected_claims,
               'expected result');
    cmp_deeply(
      get_stored_access_token($obj),
      undef,
      'not stored in session'
    );
    cmp_deeply(
      get_stored_access_token($obj, undef, 'stash'),
      \%expected_stored_token,
      'stored in stash'
    );
  };

  subtest "verify_token() with 'scp' claim" => sub {

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
    my $claims = $obj->verify_token();

    # Then
    my %expected_claims = (
      iss => 'my_issuer',
      exp => 1111111,
      aud => 'my_id',
      sub => 'my_subject',
      scp => [qw/scope1 scope2 scope3/],
    );
    my %expected_stored_token = (
      token      => 'abcd123',
      expires_at => 1111111,
      scopes     => [qw/scope1 scope2 scope3/],
    );
    cmp_deeply($claims,
               \%expected_claims,
               'expected result');
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_token,
      'expected stored access token'
    );
  };

  subtest "verify_token() with 'scope' claim" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd123' },
      claims          => { iss   => 'my_issuer',
                           exp   => 456,
                           aud   => 'my_id',
                           sub   => 'my_subject',
                           scope => 'scope4 scope5 scope6' },
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    my %expected_claims = (
      iss   => 'my_issuer',
      exp   => 456,
      aud   => 'my_id',
      sub   => 'my_subject',
      scope => 'scope4 scope5 scope6',
    );
    my %expected_stored_token = (
      token      => 'abcd123',
      expires_at => 456,
      scopes     => [qw/scope4 scope5 scope6/],
    );
    cmp_deeply($claims,
               \%expected_claims,
               'expected result');
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_token,
      'expected stored access token'
    );
  };

  subtest "verify_token() with array in 'scope' claim" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd123' },
      claims          => { iss   => 'my_issuer',
                           exp   => 456,
                           aud   => 'my_id',
                           sub   => 'my_subject',
                           scope => [qw/scope7 scope8/] },
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    my %expected_claims = (
      iss   => 'my_issuer',
      exp   => 456,
      aud   => 'my_id',
      sub   => 'my_subject',
      scope => [qw/scope7 scope8/],
    );
    my %expected_stored_token = (
      token      => 'abcd123',
      expires_at => 456,
      scopes     => [qw/scope7 scope8/],
    );
    cmp_deeply($claims,
               \%expected_claims,
               'expected result');
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_token,
      'expected stored access token'
    );
  };

  subtest "verify_token() with unexpected scopes type" => sub {

    # Given
    my $obj = build_object(
      request_headers => { Authorization => 'bearer abcd123' },
      claims          => { iss   => 'my_issuer',
                           exp   => 456,
                           aud   => 'my_id',
                           sub   => 'my_subject',
                           scope => {} },
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    my %expected_claims = (
      iss   => 'my_issuer',
      exp   => 456,
      aud   => 'my_id',
      sub   => 'my_subject',
      scope => {},
    );
    my %expected_stored_token = (
      token      => 'abcd123',
      expires_at => 456,
      scopes     => [],
    );
    cmp_deeply($claims,
               \%expected_claims,
               'expected result');
    cmp_deeply(
      get_stored_access_token($obj),
      \%expected_stored_token,
      'expected stored access token'
    );
    cmp_deeply($log->msgs->[-1],
               superhashof({
                 message => 'OIDC: unexpected scopes type : HASH',
                 level   => 'warning',
               }),
               'expected log');
  };

  subtest "verify_token() with mocked claims" => sub {

    my %mocked_claims = (sub => 'my_mocked_subject',
                         scp => [qw/scope1 scope2/]);

    # Given
    my $obj = build_object(
      config     => { mocked_claims => \%mocked_claims },
      attributes => { base_url => 'http://localhost:3000' },
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    cmp_deeply($claims, \%mocked_claims,
               'expected result');
  };

  subtest "verify_token() with mocked claims but not in local environment" => sub {

    my %mocked_claims = (sub => 'my_mocked_subject');

    # Given
    my $obj = build_object(
      config          => { mocked_claims => \%mocked_claims },
      attributes      => { base_url => 'http://my-app' },
      request_headers => { Authorization => 'bearer abcd123' }
    );

    # When
    my $claims = $obj->verify_token();

    # Then
    cmp_deeply($claims, superhashof({sub => 'my_subject'}),
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

sub test_has_scope {
  subtest "has_scope() with scopes" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { token  => 'my_access_token',
        scopes => [qw/scope11 scope12/] }
    );

    # When - Then
    ok($obj->has_scope('scope11'),
       'has scope');
    ok($obj->has_scope('scope12'),
       'has another scope');
    ok(! $obj->has_scope('scope1'),
       'has not scope');
  };

  subtest "has_scope() without scope" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { token => 'my_access_token' }
    );

    # When - Then
    ok(! $obj->has_scope('scope11'),
       'has not scope');
  };
}

sub test_get_userinfo {
  subtest "get_userinfo()" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );

    # When
    my $userinfo = $obj->get_userinfo();

    # Then
    is($userinfo->{sub}, 'DOEJ',
       'expected subject');

    cmp_deeply([ $obj->client->next_call(4) ],
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
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );

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
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );

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
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );

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
    my $obj = build_object();
    store_identity(
      $obj,
      { subject   => 'DOEJ',
        login     => 'DOEJ',
        lastname  => 'Doe',
        firstname => 'John' }
    );

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
    store_access_token(
      $obj,
      { token         => 'my_audience_access_token',
        token_type    => 'my_audience_token_type',
        refresh_token => 'my_audience_refresh_token' },
      'my_audience',
    );

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');

    cmp_deeply([ $obj->client->next_call(4) ],
               [ 'build_api_useragent', bag($obj->client, token_type => 'my_audience_token_type',
                                                          token      => 'my_audience_access_token') ],
               'expected call to client');
  };

  subtest "build_api_useragent() without access token for audience" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');

    cmp_deeply([ $obj->client->next_call(10) ],
               [ 'build_api_useragent', bag($obj->client, token_type => 'my_exchanged_token_type',
                                                          token      => 'my_exchanged_access_token') ],
               'expected call to client');
  };

  subtest "build_api_useragent() without valid access token for audience" => sub {

    # Given
    my $obj = build_object(
      config      => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      has_expired => 1,
    );
    store_access_token(
      $obj,
      { token         => 'my_audience_access_token',
        token_type    => 'my_audience_token_type',
        refresh_token => 'my_audience_refresh_token' },
      'my_audience',
    );
    store_access_token(
      $obj,
      { token         => 'my_a_token',
        refresh_token => 'my_r_token' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');

    cmp_deeply([ $obj->client->next_call(9) ],
               [ 'build_api_useragent', bag($obj->client, token_type => 'my_token_type',
                                                          token      => 'my_access_token') ],
               'expected call to client');
  };

  subtest "build_api_useragent() with error while refreshing access token for audience" => sub {
    $log->clear();

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    store_access_token(
      $obj,
      { token         => 'my_audience_access_token',
        token_type    => 'my_audience_token_type',
        refresh_token => 'my_audience_refresh_token' },
      'my_audience',
    );
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );
    my $i = 0;
    $obj->client->mock(has_expired => sub { $i++ == 0 ? die 'to have an error while refreshing token'
                                                      : 0 });

    # When
    my $ua = $obj->build_api_useragent('my_audience_alias');

    # Then
    isa_ok($ua, 'Mojo::UserAgent');

    cmp_deeply([ $obj->client->next_call(11) ],
               [ 'build_api_useragent', bag($obj->client, token_type => 'my_exchanged_token_type',
                                                          token      => 'my_exchanged_access_token') ],
               'expected call to client');

    cmp_deeply($log->msgs->[0],
               superhashof({
                 message => re('OIDC: error getting valid access token'),
                 level   => 'warning',
               }),
               'expected log');
  };

  subtest "build_api_useragent() without valid access token for audience and cannot exchange token" => sub {

    # Given
    my $obj = build_object(
      config      => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      has_expired => 1,
    );
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );
    $obj->client->mock(exchange_token => sub { die 'AAAAAhhhh !!!'; });

    # When - Then
    throws_ok {
      $obj->build_api_useragent('my_audience_alias');
    } qr/AAAAAhhhh/,
      'expected exception';
  };

  subtest "build_api_useragent() for current audience" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { token         => 'my_access_token_for_current_audience',
        token_type    => 'my_token_type_for_current_audience',
        refresh_token => 'my_refresh_token_for_current_audience' }
    );
    store_identity(
      $obj,
      { subject => 'my_subject' }
    );

    # When
    my $ua = $obj->build_api_useragent();

    # Then
    isa_ok($ua, 'Mojo::UserAgent');

    cmp_deeply([ $obj->client->next_call(4) ],
               [ 'build_api_useragent', bag($obj->client, token_type => 'my_token_type_for_current_audience',
                                                          token      => 'my_access_token_for_current_audience') ],
               'expected call to client');
  };
}

sub test_redirect_to_logout_with_id_token {
  subtest "redirect_to_logout() with id token" => sub {

    # Given
    my $obj = build_object(attributes => { logout_redirect_uri => 'my_logout_redirect_uri' });
    store_identity(
      $obj,
      { token => 'my_id_token' }
    );

    # When
    $obj->redirect_to_logout(
      state         => 'my_state',
      extra_params  => { param => 'param' },
      target_url    => 'my_target_url',
    );

    # Then
    is($obj->get_flash->('oidc_target_url'), 'my_target_url',
       'expected oidc_target_url flash');

    is($obj->redirect->(), 'my_logout_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call(2) ],
               [ 'logout_url', bag($obj->client, id_token                 => 'my_id_token',
                                                 post_logout_redirect_uri => 'my_logout_redirect_uri',
                                                 state                    => 'my_state',
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
    is($obj->get_flash->('oidc_target_url'), undef,
       'no oidc_target_url flash');

    is($obj->redirect->(), 'my_logout_url',
       'expected redirect');

    cmp_deeply([ $obj->client->next_call() ],
               [ 'logout_url', bag($obj->client, post_logout_redirect_uri => 'my_personal_logout_redirect_uri') ],
               'expected call to client');
  };
}

sub test_has_access_token_expired {
  subtest "has_access_token_expired() has expired" => sub {

    # Given
    my $obj = build_object(has_expired => 1);
    store_access_token(
      $obj,
      {}
    );

    # When
    my $has_expired = $obj->has_access_token_expired();

    # Then
    ok($has_expired, 'has expired');
  };

  subtest "has_access_token_expired() has not expired" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      {}
    );

    # When
    my $has_expired = $obj->has_access_token_expired();

    # Then
    ok(!$has_expired, 'has not expired');
  };
}

sub test_get_valid_access_token_with_exceptions {
  subtest "get_valid_access_token() without configured audience alias" => sub {

    # Given
    my $obj = build_object();

    # When - Then
    throws_ok {
      $obj->get_valid_access_token('my_audience_alias');
    } qr/no audience for alias 'my_audience_alias'/,
      'expected exception';
  };
}

sub test_get_valid_access_token {
  subtest "get_valid_access_token() with expired access token and no refresh token" => sub {

    # Given
    my $obj = build_object(has_expired => 1);
    store_access_token(
      $obj,
      { token      => 'my_access_token',
        expires_at => 1234 }
    );

    # When - Then
    is($obj->get_valid_access_token(), undef,
       'expected result');
  };

  subtest "get_valid_access_token() with expired access token" => sub {

    # Given
    my $obj = build_object(has_expired => 1);
    store_access_token(
      $obj,
      { token         => 'my_access_token',
        refresh_token => 'my_refresh_token',
        expires_at    => 1234 }
    );

    # When
    my $access_token = $obj->get_valid_access_token();

    # Then
    is($access_token->{token}, 'my_access_token',
       'expected token');
  };

  subtest "get_valid_access_token() with not expired token" => sub {

    # Given
    my $obj = build_object();
    store_access_token(
      $obj,
      { token      => 'my_stored_token',
        expires_at => 1234 }
    );

    # When
    my $access_token = $obj->get_valid_access_token();

    # Then
    is($access_token->{token}, 'my_stored_token',
       'expected token');
  };
}

sub test_get_valid_access_token_for_audience {
  subtest "get_valid_access_token() with expired exchanged token" => sub {

    # Given
    my $obj = build_object(
      config      => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      has_expired => 1,
    );
    my %expired_access_token = ( token         => 'my_old_access_token',
                                 refresh_token => 'my_old_refresh_token',
                                 expires_at    => 12 );
    store_access_token($obj, \%expired_access_token, 'my_audience');
    store_identity($obj, { subject => 'my_subject' });

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    is($exchanged_token->{token}, 'my_access_token',
       'expected token');

    cmp_deeply([ $obj->client->next_call(3) ],
               [ 'has_expired', [ $obj->client, 12 ] ],
               'expected call to client');
  };

  subtest "get_valid_access_token() with expired exchanged token and no refresh token" => sub {

    # Given
    my $obj = build_object(
      config      => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      has_expired => 1,
    );
    my %expired_access_token = ( token      => 'my_old_access_token',
                                 expires_at => 12 );
    store_access_token($obj, \%expired_access_token, 'my_audience');
    store_identity($obj, { subject => 'my_subject' });

    # When
    is($obj->get_valid_access_token('my_audience_alias'), undef,
       'expected result');
  };

  subtest "get_valid_access_token() with unexpired exchanged token" => sub {

    # Given
    my $obj = build_object(
      config => { audience_alias => { my_audience_alias => {audience => 'my_audience'} } }
    );
    my %access_token = ( token      => 'my_access_token',
                         expires_at => 1234 );
    store_access_token($obj, \%access_token, 'my_audience');

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    cmp_deeply($exchanged_token, \%access_token,
               'expected result');
  };

  subtest "get_valid_access_token() with mocked token" => sub {

    my %mocked_claims = (login => 'my_mocked_login',
                         scp   => [qw/scope1/]);

    # Given
    my $obj = build_object(
      config     => { mocked_claims  => \%mocked_claims,
                      audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      attributes => { base_url => 'http://localhost:3000' },
    );

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    my %expected_exchanged_token = (token  => q{mocked token for audience 'my_audience'},
                                    scopes => [qw/scope1/]);
    cmp_deeply($exchanged_token, \%expected_exchanged_token,
               'expected result');
  };

  subtest "get_valid_access_token() with mocked token but not in local environment" => sub {

    my %mocked_claims = (login => 'my_mocked_login');

    # Given
    my $obj = build_object(
      config     => { mocked_claims  => \%mocked_claims,
                      audience_alias => { my_audience_alias => {audience => 'my_audience'} } },
      attributes => { base_url => 'http://my-app' },
    );
    my %access_token = ( token      => 'my_access_token',
                         expires_at => 1234 );
    store_access_token($obj, \%access_token, 'my_audience');

    # When
    my $exchanged_token = $obj->get_valid_access_token('my_audience_alias');

    # Then
    cmp_deeply($exchanged_token, \%access_token,
               'expected result');
  };
}

sub test_get_stored_identity {
  subtest "get_stored_identity() without stored identity" => sub {

    # Given
    my $obj = build_object();

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    is($stored_identity, undef,
       'expected result');
  };

  subtest "get_stored_identity() with stored and valid identity" => sub {

    # Given
    my %identity = (subject    => 'my_subject',
                    expires_at => 777);
    my $obj = build_object(has_expired => 0);
    store_identity($obj, \%identity);

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    cmp_deeply($stored_identity, \%identity,
               'expected result');
  };

  subtest "get_stored_identity() with stored and expired identity" => sub {

    # Given
    my %identity = (subject    => 'my_subject',
                    expires_at => 777);
    my $obj = build_object(has_expired => 1);
    store_identity($obj, \%identity);

    # When
    my $result = $obj->get_stored_identity();

    # Then
    cmp_deeply($result, undef,
               'expected result');
  };

  subtest "get_stored_identity() with stored identity and no expiration" => sub {

    # Given
    my %identity = (subject => 'my_subject');
    my $obj = build_object(has_expired => 1);
    store_identity($obj, \%identity);

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    cmp_deeply($stored_identity, \%identity,
               'expected result');
  };

  subtest "get_stored_identity() with mocked identity" => sub {

    my %identity = (subject => 'my_mocked_subject');

    # Given
    my $obj = build_object(
      config     => { mocked_identity => \%identity },
      attributes => { base_url => 'http://localhost:3002' },
    );

    # When
    my $stored_identity = $obj->get_stored_identity();

    # Then
    cmp_deeply($stored_identity, \%identity,
               'expected result');
  };

  subtest "get_stored_identity() with mocked identity but not in local environment" => sub {

    my %identity = (subject => 'my_mocked_subject');

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

sub test_get_identity_expiration_time {
  subtest "get_identity_expiration_time() without configured leeway" => sub {

    # Given
    my %identity = (expires_at => 99999);
    my $obj = build_object();
    store_identity($obj, \%identity);

    # When
    my $expiration_time = $obj->get_identity_expiration_time();

    # Then
    is($expiration_time, 99999,
       'expected result');
  };

  subtest "get_identity_expiration_time() with configured leeway" => sub {

    # Given
    my %identity = (expires_at => 99999);
    my $obj = build_object(
      config => { expiration_leeway => 60 }
    );
    store_identity($obj, \%identity);

    # When
    my $expiration_time = $obj->get_identity_expiration_time();

    # Then
    is($expiration_time, 99939,
       'expected result');
  };

  subtest "get_identity_expiration_time() with non-expirable identity" => sub {

    # Given
    my %identity = ();
    my $obj = build_object(
      config => { expiration_leeway => 60 }
    );
    store_identity($obj, \%identity);

    # When
    my $expiration_time = $obj->get_identity_expiration_time();

    # Then
    is($expiration_time, undef,
       'expected result');
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
    id_token      => 'my_id_token',
    refresh_token => 'my_refresh_token',
    token_type    => 'my_token_type',
    expires_in    => 3600,
  );
  my %exchanged_token = (
    access_token  => 'my_exchanged_access_token',
    refresh_token => 'my_exchanged_refresh_token',
    token_type    => 'my_exchanged_token_type',
    expires_in    => 3600,
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

  my $flash = $params{flash} || {};
  my $redirect;

  return $class->new(
    log             => $log,
    store_mode      => $params{store_mode} || 'session',
    request_params  => $params{request_params} || {},
    request_headers => $params{request_headers} || {},
    session         => {},
    stash           => {},
    get_flash       => sub { return $flash->{$_[0]}; },
    set_flash       => sub { $flash->{$_[0]} = $_[1]; return; },
    redirect        => sub { if ($_[0]) { $redirect = $_[0]; return; }
                             else { return $redirect } },
    client          => $mock_client,
    base_url        => 'http://my-app/',
    current_url     => '/current-url',
    %{$params{attributes} || {}},
  );
}

sub store_identity {
  my ($obj, $identity) = @_;

  $obj->session->{oidc}{provider}{my_provider}{identity} = $identity;
}

sub get_stored_identity {
  my ($obj) = @_;

  return $obj->session->{oidc}{provider}{my_provider}{identity};
}

sub store_access_token {
  my ($obj, $token, $audience) = @_;

  $obj->session->{oidc}{provider}{my_provider}{access_token}{audience}{$audience || 'my_id'} = $token;
}

sub get_stored_access_token {
  my ($obj, $audience, $store_mode) = @_;
  $store_mode ||= 'session';

  my $store = $store_mode eq 'session' ? $obj->session
                                       : $obj->stash;

  return $store->{oidc}{provider}{my_provider}{access_token}{audience}{$audience || 'my_id'};
}

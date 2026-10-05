#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

# Live test against a real authentik. Off unless AUTHENTIK_LIVE_TEST=1,
# AUTHENTIK_URL and AUTHENTIK_TOKEN are set. Everything it makes carries a
# random prefix and is deleted at the end, so it can run beside other work on
# the same instance and twice in a row. A throwaway authentik:
# t/authentik/docker-compose.yml.

BEGIN {
  plan skip_all => 'set AUTHENTIK_LIVE_TEST=1, AUTHENTIK_URL and AUTHENTIK_TOKEN to run the authentik live test'
    unless $ENV{AUTHENTIK_LIVE_TEST} && $ENV{AUTHENTIK_URL} && $ENV{AUTHENTIK_TOKEN};
}

use AuthentikExecutor;
use Future;
use IO::Async::Loop;
use Net::Async::Authentik;

my $prefix = 'naauth-live-'.join '', map { ( 'a' .. 'z' )[ rand 26 ] } 1 .. 8;
my $password = 'Live-Password-'.join '', map { ( 'a' .. 'z', 0 .. 9 )[ rand 36 ] } 1 .. 12;

my $loop = IO::Async::Loop->new;
my $ak   = Net::Async::Authentik->new(
  base_url    => $ENV{AUTHENTIK_URL},
  application => $prefix,
  token       => $ENV{AUTHENTIK_TOKEN}
);
# nothing works before this: the HTTP client is a child notifier
$loop->add($ak);
my $api = $ak->api;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

sub twice {
  my ( $name, $code ) = @_;
  my $first  = $code->();
  my $second = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  is( $second->{changed}, '', $name.': the second run changes nothing' );
  return $first;
}

# in reverse order of creation, and never loud about it
END {
  return unless $api;
  eval { $api->delete_application_f($prefix)->get };
  my $bindings = eval { $api->list_bindings_f->get } || [];
  for my $binding ( @$bindings ) {
    my $stage = eval { $api->find_stage_f( $prefix.'-password' )->get };
    eval { $api->delete_binding_f( $binding->{pk} )->get } if $stage && $binding->{stage} eq $stage->{pk};
  }
  for my $type (qw( password authenticator/validate )) {
    my $stage = eval { $api->find_stage_f( $prefix.( $type eq 'password' ? '-password' : '-validate' ) )->get };
    eval { $api->delete_stage_f( $type, $stage->{pk} )->get } if $stage;
  }
  eval { $api->delete_flow_f( $prefix.'-flow' )->get };
  my $provider = eval { $api->find_oauth2_provider_f($prefix)->get };
  eval { $api->delete_oauth2_provider_f( $provider->{pk} )->get } if $provider;
  my $mapping = eval { $api->find_scope_mapping_f( $prefix.'-mapping' )->get };
  eval { $api->delete_scope_mapping_f( $mapping->{pk} )->get } if $mapping;
  eval { $api->delete_token_f( $prefix.'-token' )->get };
  for my $username ( $prefix, 'ak-'.$prefix.'-client_credentials' ) {
    # the second one is the service account authentik makes for the client
    # credentials grant; deleting the provider does not take it with it
    my $user = eval { $api->find_user_f($username)->get };
    eval { $api->delete_user_f( $user->{pk} )->get } if $user;
  }
  my $group = eval { $api->find_group_f( $prefix.'-group' )->get };
  eval { $api->delete_group_f( $group->{pk} )->get } if $group;
}

subtest 'the instance' => sub {
  my $version = $api->version_f->get;
  diag 'authentik '.$version->{version_current};
  ok( $version->{version_current}, 'version' );
  ok( $api->me_f->get->{user}{username}, 'the token belongs to '.$api->me_f->get->{user}{username} );
  ok( $api->settings_f->get->{default_token_duration}, 'settings' );
};

my ( $provider, $user );

subtest 'objects, twice' => sub {
  twice( group => sub { $api->ensure_group_f( name => $prefix.'-group', attributes => { probe => 'yes' } )->get } );

  $user = twice( user => sub {
    $api->ensure_user_f(
      username    => $prefix,
      name        => 'Live Test User',
      email       => $prefix.'@example.org',
      password    => $password,
      attributes  => { probe => 'yes' },
      group_names => [ $prefix.'-group' ]
    )->get;
  } )->{object};
  is( scalar @{ $user->{groups} }, 1, 'the group name was resolved' );

  twice( mapping => sub {
    $api->ensure_scope_mapping_f( name => $prefix.'-mapping', scope_name => $prefix,
      expression => 'return {"probe": True}' )->get;
  } );

  $provider = twice( provider => sub {
    $api->ensure_oauth2_provider_f(
      name                    => $prefix,
      authorization_flow_slug => 'default-provider-authorization-implicit-consent',
      invalidation_flow_slug  => 'default-provider-invalidation-flow',
      client_type             => 'confidential',
      grant_types             => [qw( authorization_code refresh_token client_credentials
                                      urn:ietf:params:oauth:grant-type:device_code )],
      # written without redirect_uri_type, which authentik fills in
      redirect_uris           => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
      scopes                  => [qw( openid email profile offline_access )],
      signing_key_name        => 'authentik Self-signed Certificate',
      sub_mode                => 'hashed_user_id'
    )->get;
  } )->{object};
  is( scalar @{ $provider->{property_mappings} }, 4, 'the scopes became property mappings' );
  is( $provider->{redirect_uris}[0]{redirect_uri_type}, 'authorization', 'and authentik filled the type in' );

  twice( application => sub {
    $api->ensure_application_f( slug => $prefix, name => 'Live Test '.$prefix, provider_name => $prefix )->get;
  } );

  twice( flow => sub {
    $api->ensure_flow_f( slug => $prefix.'-flow', name => 'Live '.$prefix, title => 'Live',
      designation => 'authentication' )->get;
  } );
  twice( stage => sub {
    $api->ensure_stage_f( password => name => $prefix.'-password',
      backends => ['authentik.core.auth.InbuiltBackend'] )->get;
  } );
  twice( binding => sub {
    $api->ensure_binding_f( flow => $prefix.'-flow', stage => $prefix.'-password', order => 20 )->get;
  } );
  twice( token => sub {
    $api->ensure_token_f( identifier => $prefix.'-token', intent => 'api', expiring => \0,
      user_name => $api->me_f->get->{user}{username} )->get;
  } );

  # one changed key is one write, and nothing else moves. The trailing
  # newline is the point: authentik trims every text field it stores, so a
  # wanted value carrying one must still settle instead of reporting a change
  # for ever.
  my $changed = $api->ensure_application_f( slug => $prefix, meta_description => "changed\n" )->get;
  is( $changed->{changed}, 'updated', 'a changed key' );
  is( $changed->{object}{meta_description}, 'changed', 'authentik stored it trimmed' );
  is( $api->find_application_f($prefix)->get->{name}, 'Live Test '.$prefix, 'and the rest is untouched' );
  is( $api->ensure_application_f( slug => $prefix, meta_description => "changed\n" )->get->{changed}, '',
    'and settles, although what was asked for can never be stored' );

  my $without = error_of {
    $api->ensure_oauth2_provider_f( name => $prefix.'-second',
      authorization_flow_slug => 'default-provider-authorization-implicit-consent',
      invalidation_flow_slug  => 'default-provider-invalidation-flow', redirect_uris => [] )->get;
  };
  isa_ok( $without, 'Net::Async::Authentik::Error::Validation', 'creating a provider without grant_types' );

  my $duplicate = error_of { $api->create_group_f( { name => $prefix.'-group' } )->get };
  is( $duplicate->http_status, 400, 'a duplicate really is 400 on the real thing' );
  ok( scalar keys %{ $duplicate->field_errors }, 'with a field error' );
};

my %client;

subtest 'OIDC' => sub {
  %client = ( client_id => $provider->{client_id}, client_secret => $provider->{client_secret} );
  my $oidc = $ak->oidc;

  is( $oidc->issuer_f->get, $ENV{AUTHENTIK_URL}.'/application/o/'.$prefix.'/', 'the issuer out of the discovery document' );
  ok( scalar @{ $oidc->jwks_f->get->{keys} }, 'jwks' );
  like( $oidc->token_endpoint_f->get, qr{/application/o/token/\z}, 'the token endpoint is instance wide' );

  my $tokens = $oidc->client_credentials_token_f( %client, scope => 'openid email profile' )->get;
  ok( $tokens->{access_token}, 'client credentials' );
  my $access = $oidc->verify_token_f( $tokens->{access_token}, audience => $client{client_id}, type => 'access' )->get;
  is( $access->{azp}, $client{client_id}, 'the access token verifies' );
  ok( $oidc->verify_token_f( $tokens->{id_token}, type => 'id' )->get, 'and the ID token' );
  like( error_of { $oidc->verify_token_f( $tokens->{id_token}, type => 'access' )->get }, qr/no scope claim/,
    'an ID token is not an access token' );
  isa_ok( error_of { $oidc->verify_token_f( $tokens->{access_token}, audience => 'somebody-else' )->get },
    'Net::Async::Authentik::Error::Validation', 'a wrong audience' );

  # every provider of one authentik signs with the same key, so with
  # issuer_mode: global the audience is all that separates two applications
  ok( $oidc->issuer_names_the_application_f->get, 'per_provider: the issuer names the application' );
  $api->update_oauth2_provider_f( $provider->{pk}, { issuer_mode => 'global' } )->get;
  # the shared HTTP client is already in the loop; a facade of its own would
  # need adding too
  my $global = Net::Async::Authentik->new( base_url => $ENV{AUTHENTIK_URL}, application => $prefix,
    http => $ak->http )->oidc;
  is( $global->issuer_f->get, $ENV{AUTHENTIK_URL}.'/', 'global: the issuer is the bare instance' );
  ok( !$global->issuer_names_the_application_f->get, 'and does not name the application' );
  my $wide = $global->client_credentials_token_f( %client, scope => 'openid' )->get;
  my $refused = error_of { $global->verify_token_f( $wide->{access_token} )->get };
  isa_ok( $refused, 'Net::Async::Authentik::Error::Validation', 'verifying without an audience' );
  like( "$refused", qr/does not name the application/, 'and says why' );
  ok( $global->verify_token_f( $wide->{access_token}, audience => $client{client_id} )->get, 'an audience makes it work' );
  ok( $global->verify_token_f( $wide->{access_token}, any_audience => 1 )->get, 'and any_audience says you meant it' );
  my $pinned = Net::Async::Authentik->new( base_url => $ENV{AUTHENTIK_URL}, application => $prefix,
    client_id => $client{client_id}, http => $ak->http )->oidc;
  ok( $pinned->verify_token_f( $wide->{access_token} )->get, 'client_id on the client does it by itself' );
  $api->update_oauth2_provider_f( $provider->{pk}, { issuer_mode => 'per_provider' } )->get;

  ok( $oidc->userinfo_f( $tokens->{access_token} )->get->{sub}, 'userinfo' );
  ok( $oidc->introspect_f( $tokens->{access_token}, %client )->get->{active}, 'introspect says active' );
  ok( $oidc->revoke_f( $tokens->{access_token}, %client )->get, 'revoke' );
  ok( !$oidc->introspect_f( $tokens->{access_token}, %client )->get->{active}, 'and it is gone' );
  is( error_of { $oidc->userinfo_f( $tokens->{access_token} )->get }->oauth_error, 'invalid_token', 'userinfo refuses it' );

  # authentik throttles the device authorization endpoint itself, not just the
  # token polling RFC 8628 means slow_down for: 20 requests an hour per client
  # IP, answered as a 429 with that same error code. Without this the whole
  # file dies on an OAuth error that says nothing about a rate limit.
  my $start;
  my $throttled = error_of { $start = $oidc->device_authorization_f( %client, scope => 'openid' )->get };
  my $status = ref $throttled ? eval { $throttled->http_status } : undef;
  BAIL_OUT( 'the device authorization endpoint is throttled: authentik allows 20 requests an hour '
    .'per client IP, raise AUTHENTIK_THROTTLE__PROVIDERS__OAUTH2__DEVICE on the instance' )
    if $status && $status == 429;
  die $throttled if $throttled;
  like( $start->{verification_uri_complete}, qr/\Q$start->{user_code}\E/, 'device_authorization' );
  my $pending = error_of { $oidc->device_token_f( device_code => $start->{device_code}, %client )->get };
  is( $pending->oauth_error, 'authorization_pending', 'the first poll is pending' );
};

subtest 'a login and the second factor' => sub {
  my %authorize = ( client_id => $client{client_id}, redirect_uri => 'https://app.example.org/cb',
    scope => 'openid email profile offline_access', state => 'live', nonce => 'live' );
  my $oidc = $ak->oidc;

  my $browser = AuthentikExecutor->new( base_url => $ENV{AUTHENTIK_URL} );
  ok( $browser->login( username => $prefix, password => $password ), 'a login with the password alone' );
  is( $browser->whoami->{username}, $prefix, 'and there is a session' );

  my $code   = $browser->authorization_code(%authorize);
  my $tokens = $oidc->exchange_authorization_code_f( %client, code => $code, redirect_uri => $authorize{redirect_uri} )->get;
  my $claims = $oidc->verify_token_f( $tokens->{id_token}, audience => $client{client_id} )->get;
  is_deeply( $claims->{amr}, ['pwd'], 'amr says password only' );
  ok( $claims->{auth_time}, 'auth_time is there' );
  is( $claims->{acr}, 'goauthentik.io/providers/oauth2/default', 'acr is the one constant value' );

  my $refreshed = $oidc->refresh_token_f( $tokens->{refresh_token}, %client )->get;
  my $after = $oidc->verify_token_f( $refreshed->{id_token} )->get;
  is_deeply( $after->{amr}, ['pwd'], 'amr survives a refresh' );
  is( $after->{auth_time}, $claims->{auth_time}, 'and so does auth_time' );
  is( error_of { $oidc->refresh_token_f( $tokens->{refresh_token}, %client )->get }->oauth_error, 'invalid_grant',
    'the refresh token was rotated' );

  my $secret = $browser->enroll_totp;
  ok( $secret, 'TOTP enrolled through the setup flow' );
  ok( scalar @{ $api->list_authenticators_f( $user->{pk} )->get }, 'and the device shows up in the API' );

  my $second = AuthentikExecutor->new( base_url => $ENV{AUTHENTIK_URL} );
  ok( $second->login( username => $prefix, password => $password, totp_secret => $secret ),
    'a login with the password and the code' );
  my $mfa = $oidc->verify_token_f(
    $oidc->exchange_authorization_code_f( %client, redirect_uri => $authorize{redirect_uri},
      code => $second->authorization_code(%authorize) )->get->{id_token}
  )->get;
  is_deeply( $mfa->{amr}, [qw( pwd mfa )], 'amr now says the second factor was used' );
  is( $mfa->{acr}, $claims->{acr}, 'acr still does not tell the two apart' );

  my $denied = AuthentikExecutor->new( base_url => $ENV{AUTHENTIK_URL} );
  my $failed = error_of { $denied->login( username => $prefix, password => 'the-wrong-password' ) };
  ok( $failed, 'a wrong password does not get in' );
};

subtest 'side by side against the real thing' => sub {
  # three ensure calls out at once, against a real authentik, and all three
  # settle on the second run the way they do one at a time
  my @first = Future->needs_all(
    $api->ensure_group_f( name => $prefix.'-par1' ),
    $api->ensure_group_f( name => $prefix.'-par2' ),
    $api->ensure_group_f( name => $prefix.'-par3' )
  )->get;
  is_deeply( [ map { $_->{changed} } @first ], [ ('created') x 3 ], 'three groups at once' );

  my @again = Future->needs_all(
    map { $api->ensure_group_f( name => $prefix.'-par'.$_ ) } 1 .. 3
  )->get;
  is_deeply( [ map { $_->{changed} } @again ], [ ('') x 3 ], 'and nothing changes on the second run' );

  # and the shared discovery holds against the real instance too
  my $fresh = Net::Async::Authentik->new( base_url => $ENV{AUTHENTIK_URL}, application => $prefix,
    http => $ak->http )->oidc;
  my @issuers = Future->needs_all( map { $fresh->issuer_f } 1 .. 5 )->get;
  is( scalar( keys %{ { map { $_ => 1 } @issuers } } ), 1, 'five callers, one issuer' );

  $api->delete_group_f( $api->find_group_f( $prefix.'-par'.$_ )->get->{pk} )->get for 1 .. 3;
};

subtest 'check_access' => sub {
  my $mine = $api->check_access_f($prefix)->get;
  ok( exists $mine->{passing}, 'check_access answers for the token owner' );
  ok( exists $api->check_access_f( $prefix, for_user => $user->{pk} )->get->{passing}, 'and for a named user' );

  # a stale id cannot pass for an answer
  my $stale = error_of { $api->check_access_f( $prefix, for_user => 999_999 )->get };
  isa_ok( $stale, 'Net::Async::Authentik::Error::API', 'a user that does not exist' );
  is( $stale->http_status, 400, 'is a field error' );
  is_deeply( $stale->field_errors, { for_user => ['User not found'] },
    'whose value authentik sends as a bare string, not a list' );

  # except for primary key 1, which is authentik's internal AnonymousUser:
  # check_access takes it although the user endpoints deny it exists
  ok( exists $api->check_access_f( $prefix, for_user => 1 )->get->{passing}, 'primary key 1 is accepted' );
  ok( error_of { $api->get_user_f(1)->get }->is_not_found, 'while get_user says there is no user 1' );
};

subtest 'clean up' => sub {
  ok( $api->delete_application_f($prefix)->get, 'application deleted' );
  is( $api->find_application_f($prefix)->get, undef, 'and gone' );
  ok( $api->delete_oauth2_provider_f( $provider->{pk} )->get, 'provider deleted' );
  is( $api->find_oauth2_provider_f($prefix)->get, undef, 'and gone' );
  ok( $api->delete_user_f( $user->{pk} )->get, 'user deleted' );
  is( $api->find_user_f($prefix)->get, undef, 'and gone' );

  # authentik leaves the service account of the client credentials grant
  # behind when the provider goes; the END block takes it as well
  my $service_account = $api->find_user_f( 'ak-'.$prefix.'-client_credentials' )->get;
  ok( $service_account, 'the client credentials service account outlives its provider' );
  ok( $api->delete_user_f( $service_account->{pk} )->get, 'and has to be deleted on its own' );
};

done_testing;

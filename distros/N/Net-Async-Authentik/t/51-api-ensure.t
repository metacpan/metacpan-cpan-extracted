#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeAuthentik;
use FakeHTTP;
use Net::Async::Authentik;

sub error_of (&) { my ( $code ) = @_; eval { $code->(); 1 } ? undef : $@ }

my $fake = FakeAuthentik->new;
my $api  = Net::Async::Authentik->new( base_url => $fake->base, token => $fake->token, http => FakeHTTP->new( fake => $fake ) )->api;

# the point of ensure_*: a second run writes nothing at all
sub twice {
  my ( $name, $code ) = @_;
  my $first = $code->();
  is( $first->{changed}, 'created', $name.': created' );
  $fake->reset_writes;
  my $second = $code->();
  is( $second->{changed}, '', $name.': the second run changes nothing' );
  is( $fake->writes, 0, $name.': and writes nothing at all' );
  return $first;
}

subtest 'ensure_group' => sub {
  my $r = twice( group => sub { $api->ensure_group_f( name => 'staff', attributes => { a => 'b' } )->get } );
  ok( $r->{object}{pk}, 'the object comes back, not just an id' );

  $fake->reset_writes;
  my $changed = $api->ensure_group_f( name => 'staff', attributes => { a => 'c' } )->get;
  is( $changed->{changed}, 'updated', 'a changed key' );
  is( $fake->writes, 1, 'in exactly one write' );
  is( $changed->{object}{attributes}{a}, 'c', 'and it took' );

  # nothing is ever deleted
  is( $api->ensure_group_f( name => 'staff' )->get->{changed}, '', 'leaving a key out changes nothing' );
  is( $api->find_group_f('staff')->get->{attributes}{a}, 'c', 'and removes nothing' );

  isa_ok( error_of { $api->ensure_group_f( attributes => {} )->get }, 'Net::Async::Authentik::Error::Validation', 'without a name' );
};

subtest 'ensure_user' => sub {
  $api->ensure_group_f( name => 'staff' )->get;
  my $r = twice( user => sub {
    $api->ensure_user_f( username => 'alice', name => 'Alice', email => 'alice@example.org',
      attributes => { dept => 'x' }, group_names => ['staff'] )->get;
  } );
  my $pk = $r->{object}{pk};
  is( $fake->passwords->{$pk}, undef, 'no password was set when none was given' );

  # attributes are merged into the current ones, because a PATCH replaces them
  $fake->reset_writes;
  is( $api->ensure_user_f( username => 'alice', attributes => { site => 'y' } )->get->{changed}, 'updated', 'another attribute' );
  is_deeply( $api->find_user_f('alice')->get->{attributes}, { dept => 'x', site => 'y' }, 'is merged, not replacing' );
  is( $api->ensure_user_f( username => 'alice', attributes => { dept => 'x' } )->get->{changed}, '', 'and a known one changes nothing' );

  ok( $api->delete_user_f($pk)->get, 'start again for the password' );
  my $created = $api->ensure_user_f( username => 'alice', name => 'Alice', password => 'a-password' )->get;
  is( $created->{changed}, 'created', 'created with a password' );
  is( $fake->passwords->{ $created->{object}{pk} }, 'a-password', 'which was set' );

  # a password is set once; a setup that runs again must not reset it
  $fake->passwords->{ $created->{object}{pk} } = 'changed-by-the-user';
  $fake->reset_writes;
  is( $api->ensure_user_f( username => 'alice', name => 'Alice', password => 'a-password' )->get->{changed}, '',
    'the second run changes nothing' );
  is( $fake->passwords->{ $created->{object}{pk} }, 'changed-by-the-user', 'and does not set the password again' );
  is( $fake->writes, 0, 'no write at all' );

  isa_ok( error_of { $api->ensure_user_f( name => 'x' )->get }, 'Net::Async::Authentik::Error::Validation', 'without a username' );
};

subtest 'ensure_oauth2_provider' => sub {
  my %wanted = (
    name                    => 'probe',
    authorization_flow_slug => 'default-provider-authorization-implicit-consent',
    invalidation_flow_slug  => 'default-provider-invalidation-flow',
    client_type             => 'confidential',
    grant_types             => [qw( authorization_code refresh_token )],
    redirect_uris           => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
    scopes                  => [qw( openid email profile )],
    signing_key_name        => 'authentik Self-signed Certificate'
  );
  my $r = twice( provider => sub { $api->ensure_oauth2_provider_f(%wanted)->get } );
  ok( $r->{object}{client_secret}, 'the client secret comes back' );
  # authentik reorders property_mappings and adds redirect_uri_type; neither
  # may look like a change on the next run
  is( scalar @{ $r->{object}{property_mappings} }, 3, 'the scopes became property mappings' );
  is( $r->{object}{redirect_uris}[0]{redirect_uri_type}, 'authorization', 'and authentik filled the type in' );

  $fake->reset_writes;
  is( $api->ensure_oauth2_provider_f( %wanted, client_type => 'public' )->get->{changed}, 'updated', 'a changed key' );
  is( $fake->writes, 1, 'one write' );

  my $without = error_of { $api->ensure_oauth2_provider_f( name => 'second',
    authorization_flow_slug => 'default-provider-authorization-implicit-consent',
    invalidation_flow_slug  => 'default-provider-invalidation-flow',
    redirect_uris => [] )->get };
  isa_ok( $without, 'Net::Async::Authentik::Error::Validation', 'creating one without grant_types' );
  like( "$without", qr/invalid_grant/, 'and says what would go wrong' );

  # an existing provider does not need them again
  is( $api->ensure_oauth2_provider_f( name => 'probe', client_type => 'confidential' )->get->{changed}, 'updated',
    'updating one without grant_types is fine' );
};

subtest 'ensure_application' => sub {
  my $r = twice( application => sub {
    $api->ensure_application_f( slug => 'probe-app', name => 'Probe App', provider_name => 'probe' )->get;
  } );
  is( $r->{object}{provider}, $api->find_oauth2_provider_f('probe')->get->{pk}, 'the provider name was resolved' );
  is( $api->ensure_application_f( slug => 'probe-app', name => 'Renamed' )->get->{changed}, 'updated', 'a new name' );
  is( $api->find_application_f('probe-app')->get->{name}, 'Renamed', 'updates instead of creating a second one' );
  isa_ok( error_of { $api->ensure_application_f( name => 'x' )->get }, 'Net::Async::Authentik::Error::Validation', 'without a slug' );
};

subtest 'ensure_scope_mapping and ensure_flow' => sub {
  twice( mapping => sub {
    $api->ensure_scope_mapping_f( name => 'probe-amr', scope_name => 'amr', expression => 'return {}' )->get;
  } );
  twice( flow => sub {
    $api->ensure_flow_f( slug => 'probe-flow', name => 'Probe', title => 'Probe', designation => 'authentication' )->get;
  } );
  is( $api->ensure_flow_f( slug => 'probe-flow', title => 'Probe again' )->get->{changed}, 'updated', 'a changed title' );
};

subtest 'ensure_stage' => sub {
  twice( stage => sub {
    $api->ensure_stage_f( password => name => 'probe-password', backends => ['authentik.core.auth.InbuiltBackend'] )->get;
  } );
  is( $api->ensure_stage_f( password => name => 'probe-password', failed_attempts_before_cancel => 3 )->get->{changed},
    'updated', 'a changed key' );

  # configure needs its configuration stage in the same write
  $api->ensure_stage_f( 'authenticator/totp', name => 'probe-totp-setup' )->get;
  $fake->reset_writes;
  my $r = $api->ensure_stage_f( 'authenticator/validate',
    name                      => 'probe-validate',
    not_configured_action     => 'configure',
    configuration_stage_names => ['probe-totp-setup'] )->get;
  is( $r->{changed}, 'created', 'a validation stage that configures' );
  is( $r->{object}{not_configured_action}, 'configure', 'with the action' );
  is( scalar @{ $r->{object}{configuration_stages} }, 1, 'and the stage it points at' );

  my $alone = error_of { $api->ensure_stage_f( 'authenticator/validate', name => 'probe-validate-2',
    not_configured_action => 'configure' )->get };
  is_deeply( [ keys %{ $alone->field_errors } ], ['not_configured_action'],
    'authentik refuses configure without a configuration stage' );

  # a stage name is unique across the types, so a clash must say so and not
  # come out as a confusing 404 from the typed endpoint
  my $clash = error_of { $api->ensure_stage_f( user_login => name => 'probe-password' )->get };
  isa_ok( $clash, 'Net::Async::Authentik::Error::Validation', 'a name that belongs to another stage type' );
  like( "$clash", qr/not of the type user_login/, 'and says which type it really is' );

  isa_ok( error_of { $api->ensure_stage_f( all => name => 'x' )->get }, 'Net::Async::Authentik::Error::Validation', 'through /stages/all/' );
  isa_ok( error_of { $api->ensure_stage_f( 'password' )->get }, 'Net::Async::Authentik::Error::Validation', 'without a name' );
};

subtest 'ensure_binding' => sub {
  my $r = twice( binding => sub { $api->ensure_binding_f( flow => 'probe-flow', stage => 'probe-password', order => 20 )->get } );
  is( $r->{object}{target}, $api->find_flow_f('probe-flow')->get->{pk}, 'the flow slug was resolved' );
  is( $r->{object}{stage}, $api->find_stage_f('probe-password')->get->{pk}, 'and the stage name' );

  # a flow binds a stage once; another order moves the binding
  my $moved = $api->ensure_binding_f( flow => 'probe-flow', stage => 'probe-password', order => 30 )->get;
  is( $moved->{changed}, 'updated', 'another order moves it' );
  is( $moved->{object}{pk}, $r->{object}{pk}, 'the same binding' );
  is( scalar @{ $api->list_bindings_f( target => $r->{object}{target} )->get }, 1, 'and there is still only one' );

  like( error_of { $api->ensure_binding_f( flow => 'no-such-flow', stage => 'probe-password', order => 10 )->get },
    qr/no flow "no-such-flow"/, 'an unknown flow' );
  like( error_of { $api->ensure_binding_f( flow => 'probe-flow', stage => 'no-such-stage', order => 10 )->get },
    qr/no stage "no-such-stage"/, 'an unknown stage' );
  isa_ok( error_of { $api->ensure_binding_f( flow => 'probe-flow', stage => 'probe-password' )->get },
    'Net::Async::Authentik::Error::Validation', 'without an order' );
};

subtest 'ensure_token' => sub {
  twice( token => sub { $api->ensure_token_f( identifier => 'probe-token', intent => 'api', expiring => \0 )->get } );
  is( $api->view_token_key_f('probe-token')->get->{key}, 'generated-key-probe-token', 'authentik made a key' );

  $api->delete_token_f('probe-token')->get;
  my $own = $api->ensure_token_f( identifier => 'probe-token', intent => 'api', expiring => \0, key => 'a-key-of-my-own' )->get;
  is( $own->{changed}, 'created', 'created with a key of our own' );
  is( $api->view_token_key_f('probe-token')->get->{key}, 'a-key-of-my-own', 'which was set' );

  $fake->reset_writes;
  is( $api->ensure_token_f( identifier => 'probe-token', intent => 'api', expiring => \0, key => 'a-key-of-my-own' )->get->{changed},
    '', 'the second run changes nothing' );
  is( $fake->writes, 0, 'and does not set the key again' );

  # authentik ignores expires, so wanting a value could never converge
  my $refused = error_of { $api->ensure_token_f( identifier => 'x', expires => '2027-01-01T00:00:00Z' )->get };
  isa_ok( $refused, 'Net::Async::Authentik::Error::Validation', 'asking for an expiry' );
  like( "$refused", qr/default_token_duration/, 'and says where the expiry comes from' );

  isa_ok( error_of { $api->ensure_token_f( intent => 'api' )->get }, 'Net::Async::Authentik::Error::Validation', 'without an identifier' );
};

done_testing;

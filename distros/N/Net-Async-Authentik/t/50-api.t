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

subtest 'transport' => sub {
  is( $api->api_url, $fake->base.'/api/v3', 'api_url' );
  my $result = $api->call_f( GET => '/core/users/me/' )->get;
  is( $result->{status}, 200, 'a call comes back' );
  is( $result->{data}{user}{username}, 'akadmin', 'with the data' );
  is( $api->call_f( GET => 'core/users/me/' )->get->{status}, 200, 'a leading slash is added' );

  # authentik answers a path without the trailing slash with 404, and call()
  # adds nothing: a raw caller gets what it asked for
  isa_ok( error_of { $api->call_f( GET => '/core/users' )->get }, 'Net::Async::Authentik::Error::API', 'a path without a trailing slash' );

  my $sent = $fake->requests->[0];
  is( $sent->[0], 'GET', 'the method' );
  like( $sent->[1], qr{\A/api/v3/core/users/me/}, 'the path' );
};

subtest 'instance' => sub {
  is( $api->version_f->get->{version_current}, '2026.8.3', 'version' );
  is( $api->settings_f->get->{default_token_duration}, 'days=1', 'settings' );
  ok( $api->config_f->get, 'config' );
  is( $api->me_f->get->{user}{username}, 'akadmin', 'me' );
};

subtest 'pagination' => sub {
  my $many = FakeAuthentik->new;
  $many->add( users => { username => sprintf( 'bulk-%03d', $_ ), name => 'Bulk '.$_ } ) for 1 .. 25;
  my $small = Net::Async::Authentik::API->new( base_url => $many->base, token => $many->token, http => FakeHTTP->new( fake => $many ), page_size => 10 );
  my $all = $small->list_users_f->get;
  is( scalar @$all, 26, 'every user, over three pages' );
  is( scalar @{ $many->requests }, 3, 'in three requests' );

  is( scalar @{ $small->list_users_f( username => 'bulk-001' )->get }, 1, 'a filter narrows it' );
  is( scalar @{ $small->list_users_f( username => 'nobody' )->get }, 0, 'and can find nothing' );

  # an answer whose next points at a page already fetched must not loop
  $many->break_pagination;
  my $guarded = $small->list_users_f->get;
  cmp_ok( scalar @$guarded, '>', 0, 'a broken pagination still returns' );
  cmp_ok( scalar @$guarded, '<=', 26, 'and does not run away' );
};

subtest 'users' => sub {
  my $user = $api->create_user_f( { username => 'alice', name => 'Alice', email => 'alice@example.org', attributes => { dept => 'x' } } )->get;
  ok( $user->{pk}, 'create_user gives the object back, with its pk' );
  is( $user->{type}, 'internal', 'with the defaults authentik fills in' );

  my $duplicate = error_of { $api->create_user_f( { username => 'alice', name => 'Alice again' } )->get };
  is( $duplicate->http_status, 400, 'a duplicate is 400, not 409' );
  is_deeply( $duplicate->field_errors, { username => ['This field must be unique.'] }, 'with a field error' );

  is( $api->find_user_f('alice')->get->{pk}, $user->{pk}, 'find_user' );
  is( $api->find_user_f('Alice')->get, undef, 'which is case sensitive, the way authentik stores names' );
  is( $api->find_user_f('nobody')->get, undef, 'and finds nothing when there is nothing' );
  is( $api->get_user_f( $user->{pk} )->get->{username}, 'alice', 'get_user' );
  ok( error_of { $api->get_user_f(999999)->get }->is_not_found, 'and 404 for an unknown pk' );

  my $patched = $api->update_user_f( $user->{pk}, { name => 'Alice B', attributes => { site => 'y' } } )->get;
  is( $patched->{name}, 'Alice B', 'update_user writes' );
  is( $patched->{email}, 'alice@example.org', 'and leaves what it was not told about' );
  is_deeply( $patched->{attributes}, { site => 'y' }, 'but attributes are replaced as a whole' );

  ok( $api->set_password_f( $user->{pk}, 'a-password' )->get, 'set_password' );
  is( $fake->passwords->{ $user->{pk} }, 'a-password', 'and it arrived' );

  my $account = $api->create_service_account_f( name => 'provisioner' )->get;
  ok( $account->{token}, 'create_service_account hands the token out' );
  is( $api->find_user_f('provisioner')->get->{type}, 'service_account', 'and makes a service account' );
  isa_ok( error_of { $api->create_service_account_f->get }, 'Net::Async::Authentik::Error::Validation', 'without a name' );

  is_deeply( $api->list_authenticators_f( $user->{pk} )->get, [], 'list_authenticators' );

  ok( $api->delete_user_f( $user->{pk} )->get, 'delete_user' );
  ok( error_of { $api->delete_user_f( $user->{pk} )->get }->is_not_found, 'and it is gone' );
};

subtest 'groups' => sub {
  my $group = $api->create_group_f( { name => 'staff', attributes => { a => 'b' } } )->get;
  ok( $group->{pk}, 'create_group' );
  is_deeply( error_of { $api->create_group_f( { name => 'staff' } )->get }->field_errors,
    { name => ['Group with this name already exists.'] }, 'a duplicate' );
  is( $api->find_group_f('staff')->get->{pk}, $group->{pk}, 'find_group' );
  is( $api->get_group_f( $group->{pk} )->get->{name}, 'staff', 'get_group' );

  my $user = $api->create_user_f( { username => 'bob', name => 'Bob' } )->get;
  ok( $api->add_user_to_group_f( $group->{pk}, $user->{pk} )->get, 'add_user_to_group' );
  is_deeply( $api->get_group_f( $group->{pk} )->get->{users}, [ $user->{pk} ], 'and he is in' );
  ok( $api->remove_user_from_group_f( $group->{pk}, $user->{pk} )->get, 'remove_user_from_group' );
  ok( $api->remove_user_from_group_f( $group->{pk}, $user->{pk} )->get, 'which does not mind a second time' );
  is_deeply( $api->get_group_f( $group->{pk} )->get->{users}, [], 'and he is out' );

  is( $api->update_group_f( $group->{pk}, { attributes => { a => 'c' } } )->get->{attributes}{a}, 'c', 'update_group' );
  ok( $api->delete_group_f( $group->{pk} )->get, 'delete_group' );
  $api->delete_user_f( $user->{pk} )->get;
};

subtest 'tokens' => sub {
  my $token = $api->create_token_f( { identifier => 'provisioner', intent => 'api', expiring => \0 } )->get;
  ok( $token->{pk}, 'create_token' );
  is_deeply( error_of { $api->create_token_f( { identifier => 'provisioner' } )->get }->field_errors,
    { identifier => ['Token with this identifier already exists.'] }, 'a duplicate' );
  is( $api->find_token_f('provisioner')->get->{intent}, 'api', 'find_token by identifier' );
  is( $api->find_token_f('nope')->get, undef, 'and nothing for an unknown one' );
  ok( $api->view_token_key_f('provisioner')->get->{key}, 'view_token_key' );
  ok( $api->set_token_key_f( 'provisioner', 'a-key-of-my-own' )->get, 'set_token_key' );
  is( $api->view_token_key_f('provisioner')->get->{key}, 'a-key-of-my-own', 'and it stuck' );
  is( $api->update_token_f( 'provisioner', { description => 'x' } )->get->{description}, 'x', 'update_token' );
  ok( $api->delete_token_f('provisioner')->get, 'delete_token' );
};

subtest 'applications and providers' => sub {
  my $flow = $api->find_flow_f('default-provider-authorization-implicit-consent')->get;
  ok( $flow->{pk}, 'the seeded flows are there' );

  my $bare = error_of { $api->create_oauth2_provider_f( { name => 'probe' } )->get };
  is_deeply( [ sort keys %{ $bare->field_errors } ], [qw( authorization_flow invalidation_flow redirect_uris )],
    'a provider needs its flows and redirect URIs' );

  my $provider = $api->create_oauth2_provider_f( {
    name => 'probe', authorization_flow => $flow->{pk}, invalidation_flow => $flow->{pk},
    redirect_uris => [ { matching_mode => 'strict', url => 'https://app.example.org/cb' } ],
    grant_types => ['authorization_code']
  } )->get;
  ok( $provider->{client_id} && $provider->{client_secret}, 'authentik generates the client credentials' );
  is( $provider->{redirect_uris}[0]{redirect_uri_type}, 'authorization', 'and fills in redirect_uri_type' );
  is( $api->find_oauth2_provider_f('probe')->get->{pk}, $provider->{pk}, 'find_oauth2_provider' );
  is( $api->get_oauth2_provider_f( $provider->{pk} )->get->{name}, 'probe', 'get_oauth2_provider' );

  my $bad_grant = error_of { $api->update_oauth2_provider_f( $provider->{pk}, { grant_types => ['banana'] } )->get };
  is_deeply( $bad_grant->field_errors, { 'grant_types.0' => ['"banana" is not a valid choice.'] },
    'a nested field error is flattened' );

  my $app = $api->create_application_f( { name => 'Probe App', slug => 'probe-app', provider => $provider->{pk} } )->get;
  is( $app->{slug}, 'probe-app', 'create_application' );
  is( $api->find_application_f('probe-app')->get->{provider}, $provider->{pk}, 'find_application' );
  is( $api->find_application_f('nope')->get, undef, 'and nothing for an unknown slug' );
  is_deeply( error_of { $api->create_application_f( { name => 'Second', slug => 'second', provider => $provider->{pk} } )->get }->field_errors,
    { provider => ['Application with this provider already exists.'] }, 'a provider belongs to one application' );

  my $urls = $api->provider_setup_urls_f( $provider->{pk} )->get;
  is( $urls->{issuer}, $fake->base.'/application/o/probe-app/', 'provider_setup_urls knows the application' );
  ok( $api->preview_user_f( $provider->{pk}, 1 )->get->{preview}, 'preview_user' );
  ok( $api->check_access_f('probe-app')->get->{passing}, 'check_access' );

  ok( $api->delete_application_f('probe-app')->get, 'delete_application' );
  ok( $api->delete_oauth2_provider_f( $provider->{pk} )->get, 'delete_oauth2_provider' );
};

subtest 'scope mappings' => sub {
  my $mappings = $api->list_scope_mappings_f->get;
  is( scalar @$mappings, 4, 'the default scope mappings' );
  my $found = $api->find_scope_mappings_by_scope_f(qw( openid email ))->get;
  is( scalar @$found, 2, 'find_scope_mappings_by_scope' );
  is( $found->[0]{scope_name}, 'openid', 'in the order the scopes were given' );
  isa_ok( error_of { $api->find_scope_mappings_by_scope_f('no-such-scope')->get }, 'Net::Async::Authentik::Error::Validation', 'an unknown scope' );

  my $mapping = $api->create_scope_mapping_f( { name => 'probe', scope_name => 'probe', expression => 'return {}' } )->get;
  ok( $mapping->{pk}, 'create_scope_mapping' );
  is( $api->find_scope_mapping_f('probe')->get->{pk}, $mapping->{pk}, 'find_scope_mapping' );
  is( $api->update_scope_mapping_f( $mapping->{pk}, { description => 'x' } )->get->{description}, 'x', 'update_scope_mapping' );
  ok( $api->test_property_mapping_f( $mapping->{pk}, user => 1 )->get->{successful}, 'test_property_mapping' );
  ok( $api->delete_scope_mapping_f( $mapping->{pk} )->get, 'delete_scope_mapping' );
};

subtest 'flows, stages and bindings' => sub {
  my $flow = $api->create_flow_f( { name => 'Probe', slug => 'probe-flow', title => 'Probe', designation => 'authentication' } )->get;
  ok( $flow->{pk}, 'create_flow' );
  is( $api->find_flow_f('probe-flow')->get->{title}, 'Probe', 'find_flow' );
  like( $api->export_flow_f('probe-flow')->get, qr/\Aversion: 1/, 'export_flow gives the YAML as a string' );

  ok( scalar @{ $api->stage_types_f->get }, 'stage_types' );
  my $stage = $api->create_stage_f( password => { name => 'probe-password', backends => ['authentik.core.auth.InbuiltBackend'] } )->get;
  ok( $stage->{pk}, 'create_stage' );
  is_deeply( error_of { $api->create_stage_f( user_login => { name => 'probe-password' } )->get }->field_errors,
    { name => ['stage with this name already exists.'] }, 'a stage name is unique across the types' );
  is( $api->find_stage_f('probe-password')->get->{pk}, $stage->{pk}, 'find_stage' );
  is( $api->get_stage_f( password => $stage->{pk} )->get->{failed_attempts_before_cancel}, undef, 'get_stage through the typed endpoint' );
  is( $api->update_stage_f( password => $stage->{pk}, { failed_attempts_before_cancel => 3 } )->get->{failed_attempts_before_cancel},
    3, 'update_stage' );

  # /stages/all/ can only be read
  my $refused = error_of { $api->update_stage_f( all => $stage->{pk}, {} )->get };
  isa_ok( $refused, 'Net::Async::Authentik::Error::Validation', 'writing through /stages/all/' );
  like( "$refused", qr{can only be read}, 'and says so' );
  isa_ok( error_of { $api->get_stage_f( undef, 'x' )->get }, 'Net::Async::Authentik::Error::Validation', 'without a type' );

  my $binding = $api->create_binding_f( { target => $flow->{pk}, stage => $stage->{pk}, order => 20 } )->get;
  ok( $binding->{pk}, 'create_binding' );
  is_deeply( error_of { $api->create_binding_f( { target => $flow->{pk}, stage => $stage->{pk}, order => 20 } )->get }->field_errors,
    { non_field_errors => ['The fields target, stage, order must make a unique set.'] }, 'target, stage and order are unique' );
  is( scalar @{ $api->list_bindings_f( target => $flow->{pk} )->get }, 1, 'list_bindings by target' );
  # authentik wants the UUID; a slug is the readable way in
  is( scalar @{ $api->list_bindings_f( flow => 'probe-flow' )->get }, 1, 'list_bindings by flow slug' );
  is( scalar @{ $api->list_bindings_f( flow => $flow->{pk} )->get }, 1, 'and by flow UUID' );
  isa_ok( error_of { $api->list_bindings_f( flow => 'no-such-flow' )->get },
    'Net::Async::Authentik::Error::Validation', 'an unknown flow slug' );
  is( $api->update_binding_f( $binding->{pk}, { order => 30 } )->get->{order}, 30, 'update_binding' );
  is_deeply( $api->find_flow_f('probe-flow')->get->{stages}, [ $stage->{pk} ], 'the flow lists the stage' );

  ok( $api->delete_binding_f( $binding->{pk} )->get, 'delete_binding' );
  ok( $api->delete_stage_f( password => $stage->{pk} )->get, 'delete_stage' );
  ok( $api->delete_flow_f('probe-flow')->get, 'delete_flow' );
};

subtest 'brands, certificates and blueprints' => sub {
  ok( $api->current_brand_f->get, 'current_brand' );
  ok( scalar @{ $api->list_brands_f->get }, 'list_brands' );
  # the public view cannot be written back; the list is where the key is
  my ( $brand ) = grep { $_->{default} } @{ $api->list_brands_f->get };
  ok( $brand && $brand->{brand_uuid}, 'the list carries the brand_uuid' );
  is( $api->update_brand_f( $brand->{brand_uuid}, { branding_title => 'Probe' } )->get->{branding_title}, 'Probe', 'update_brand' );

  is( $api->find_certificate_f('authentik Self-signed Certificate')->get->{private_key_available}, 1, 'find_certificate' );
  is( $api->find_certificate_f('nope')->get, undef, 'and nothing for an unknown one' );

  my $blueprint = $api->create_blueprint_f( { name => 'probe', content => "version: 1\n" } )->get;
  is( $blueprint->{status}, 'unknown', 'a new blueprint has not run yet' );
  is( $api->apply_blueprint_f( $blueprint->{pk} )->get->{status}, 'successful', 'apply_blueprint' );
  is( $api->get_blueprint_f( $blueprint->{pk} )->get->{status}, 'successful', 'get_blueprint' );
  ok( $api->delete_blueprint_f( $blueprint->{pk} )->get, 'delete_blueprint' );
};

done_testing;

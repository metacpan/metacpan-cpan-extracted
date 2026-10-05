#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use FakeKeycloak;
use FakeHTTP;
use Net::Async::Keycloak;

my $fake = FakeKeycloak->new;
my $http = FakeHTTP->new( fake => $fake );
my $kc   = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', http => $http );
my $admin = $kc->admin;

subtest 'realm' => sub {
  is( $admin->create_realm_f( { displayName => 'Main' } )->get, 'main', 'create_realm returns the realm name' );
  is( $admin->get_realm_f->get->{displayName}, 'Main', 'get_realm' );
  ok( $admin->update_realm_f( { accessTokenLifespan => 600 } )->get, 'update_realm' );
  is( $admin->get_realm_f->get->{accessTokenLifespan}, 600, 'updated' );
  is( $admin->get_realm_f->get->{displayName}, 'Main', 'the rest untouched' );
  is( $admin->server_info_f->get->{systemInfo}{version}, '26.8.0', 'server_info from the server root' );
  my $request = $fake->requests->[-1];
  is( $request->uri->path, '/admin/serverinfo', 'which is not under the realm' );
  is( $request->header('Authorization'), 'Bearer '.$kc->auth->token_f->get, 'with the admin token' );
  is( $admin->partial_import_f( { users => [ { username => 'Imported' } ] }, if_exists => 'SKIP' )->get->{added}, 1, 'partial_import' );
};

subtest 'clients' => sub {
  my $id = $admin->create_client_f( { clientId => 'cli', publicClient => \1 } )->get;
  like( $id, qr/\Aid-\d+\z/, 'create_client returns the id from the Location header' );
  is( $admin->get_client_f($id)->get->{clientId}, 'cli', 'get_client' );
  is( $admin->find_client_f('cli')->get->{id}, $id, 'find_client by clientId' );
  is( $admin->find_client_f('nope')->get, undef, 'find_client without a match' );
  my $client = $admin->get_client_f($id)->get;
  ok( $admin->update_client_f( $id, { %$client, description => 'd' } )->get, 'update_client' );
  is( $admin->get_client_f($id)->get->{description}, 'd', 'updated' );
  is( scalar @{ $admin->list_clients_f->get }, 1, 'list_clients' );
  is( $admin->get_client_secret_f($id)->get->{type}, 'secret', 'get_client_secret' );
  is( $admin->get_service_account_user_f($id)->get->{username}, 'service-account-cli', 'get_service_account_user' );
  ok( !eval { $admin->create_client_f( { clientId => 'cli' } )->get; 1 }, 'a second create croaks' );
  ok( $@->is_conflict, 'with a conflict' );
  ok( $admin->delete_client_f($id)->get, 'delete_client' );
  ok( !eval { $admin->get_client_f($id)->get; 1 } && $@->is_not_found, 'gone' );
};

subtest 'client scopes and protocol mappers' => sub {
  my $client = $admin->create_client_f( { clientId => 'mapped' } )->get;
  my $scope  = $admin->create_client_scope_f( { name => 'amr', protocol => 'openid-connect' } )->get;
  is( $admin->find_client_scope_f('amr')->get->{id}, $scope, 'find_client_scope by name' );
  my $mapper = $admin->create_protocol_mapper_f( client => $client, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => {} } )->get;
  ok( $mapper, 'create_protocol_mapper on a client' );
  is( $admin->list_protocol_mappers_f( client => $client )->get->[0]{name}, 'amr', 'list_protocol_mappers' );
  ok( $admin->update_protocol_mapper_f( client => $client, $mapper, { name => 'amr', protocolMapper => 'oidc-amr-mapper', config => { a => 'b' } } )->get, 'update_protocol_mapper' );
  is( $admin->list_protocol_mappers_f( client => $client )->get->[0]{config}{a}, 'b', 'updated' );
  ok( $admin->create_protocol_mapper_f( client_scope => $scope, { name => 'amr', protocolMapper => 'oidc-amr-mapper' } )->get, 'on a client scope' );
  like( $fake->requests->[-1]->uri->path, qr{/client-scopes/\Q$scope\E/protocol-mappers/models\z}, 'at the scope' );
  ok( $admin->delete_protocol_mapper_f( client => $client, $mapper )->get, 'delete_protocol_mapper' );
  ok( !eval { $admin->list_protocol_mappers_f( group => 'x' )->get; 1 }, 'an owner that is neither client nor scope' );
  isa_ok( $@, 'Net::Async::Keycloak::Error::Validation' );
  ok( $admin->add_default_client_scope_f( $client, $scope )->get, 'add_default_client_scope' );
  ok( $admin->add_realm_default_client_scope_f($scope)->get, 'add_realm_default_client_scope' );
};

subtest 'users' => sub {
  my $id = $admin->create_user_f( { username => 'Alice', enabled => \1, credentials => [ { type => 'password', value => 'pw', temporary => \0 } ] } )->get;
  is( $admin->find_user_f('alice')->get->{id}, $id, 'find_user' );
  is( $admin->find_user_f('ALICE')->get->{id}, $id, 'in any case' );
  is( $admin->find_user_f('alic')->get, undef, 'exactly' );
  is_deeply( [ map { $_->{type} } @{ $admin->list_credentials_f($id)->get } ], ['password'], 'list_credentials' );
  ok( $admin->set_password_f( $id, 'new', temporary => 1 )->get, 'set_password' );
  my ( $password ) = grep { $_->{type} eq 'password' } @{ $fake->realm('main')->{users}{$id}{credentials} };
  is_deeply( [ @$password{qw( value type )}, ${ $password->{temporary} } ], [ 'new', 'password', 1 ], 'with type and temporary flag' );
  ok( $admin->update_user_f( $id, { firstName => 'A' } )->get, 'update_user' );
  is( $admin->get_user_f($id)->get->{firstName}, 'A', 'updated' );
  is_deeply( $admin->list_sessions_f($id)->get, [], 'list_sessions' );
  ok( $admin->logout_user_f($id)->get, 'logout_user' );
  ok( $admin->delete_credential_f( $id, $admin->list_credentials_f($id)->get->[0]{id} )->get, 'delete_credential' );
  ok( $admin->delete_user_f($id)->get, 'delete_user' );
};

subtest 'authentication' => sub {
  is_deeply( [ map { $_->{alias} } @{ $admin->list_flows_f->get } ], [ 'browser', 'direct grant' ], 'list_flows' );
  my ( $otp ) = grep { ( $_->{providerId} // '' ) eq 'auth-otp-form' } @{ $admin->list_executions_f('browser')->get };
  ok( $otp, 'list_executions' );
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/browser/executions\z}, 'by alias' );
  $admin->list_executions_f('direct grant')->get;
  like( $fake->requests->[-1]->uri->as_string, qr{/flows/direct%20grant/executions\z}, 'an alias with a space is escaped' );
  my $config = $admin->create_execution_config_f( $otp->{id}, { alias => 'x', config => { 'default.reference.value' => 'otp' } } )->get;
  ok( $config, 'create_execution_config' );
  is( $admin->get_execution_config_f($config)->get->{config}{'default.reference.value'}, '**********', 'get_execution_config: masked, as Keycloak does' );
  ok( $admin->update_execution_config_f( $config, { alias => 'x', config => { 'default.reference.value' => 'mfa' } } )->get, 'update_execution_config' );
  is( $fake->realm('main')->{configs}{$config}{config}{'default.reference.value'}, 'mfa', 'updated' );
  is( $fake->realm('main')->{configs}{$config}{id}, $config, 'with its id' );
  ok( $admin->copy_flow_f( 'browser', 'browser-copy' )->get, 'copy_flow' );
  is_deeply( $admin->describe_authenticator_f('auth-otp-form')->get, { properties => [] }, 'describe_authenticator' );
};

subtest 'call reaches what has no method' => sub {
  my $result = $admin->call_f( GET => '/clients?first=0&max=1' )->get;
  is( $result->{status}, 200, 'status' );
  is( ref $result->{data}, 'ARRAY', 'data' );
};

subtest 'a refused token is renewed once' => sub {
  $admin->get_realm_f->get;
  @{ $fake->logins } = ();
  $fake->forget_tokens;
  ok( $admin->get_realm_f->get, 'the call after a Keycloak restart succeeds' );
  is( scalar @{ $fake->logins }, 1, 'after one new login' );

  my $fixed = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', token => 'stale', http => $http );
  ok( !eval { $fixed->admin->get_realm_f->get; 1 }, 'a fixed token that is refused croaks' );
  ok( $@->is_unauthorized, 'with 401' );

  my $always = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', username => 'admin', password => 'admin', http => $http );
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply( 401, { error => 'HTTP 401 Unauthorized' } ) };
  @{ $fake->logins } = ();
  ok( !eval { $always->admin->get_realm_f->get; 1 }, 'a token refused twice croaks' );
  is( scalar @{ $fake->logins }, 2, 'after exactly one retry' );
};

subtest 'a failed login is not retried as a refused token' => sub {
  my $bad = Net::Async::Keycloak->new( base_url => $fake->base, realm => 'main', client_id => 'svc', client_secret => 'wrong', http => $http );
  @{ $fake->logins } = ();
  ok( !eval { $bad->admin->get_realm_f->get; 1 }, 'a wrong client secret croaks' );
  like( "$@", qr/admin login failed: 401/, 'as a failed login' );
  is( scalar @{ $fake->logins }, 1, 'and the secret went to Keycloak once, not twice' );
};

subtest 'no Location header' => sub {
  no warnings 'redefine';
  local *FakeKeycloak::_admin = sub { $_[0]->_reply(201) };
  ok( !eval { $admin->create_client_f( { clientId => 'x' } )->get; 1 }, 'croaks instead of returning nothing' );
  like( "$@", qr/sent no Location header/, 'and says why' );
};

done_testing;

package Net::Async::Keycloak::Admin;

# ABSTRACT: Keycloak Admin REST API for one realm, asynchronously, with idempotent ensure methods

use Moo;
with 'Net::Async::Keycloak::Role::HTTP';
with 'WWW::Keycloak::Role::HTTP';
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf Object Str );
use Net::Async::Keycloak::Error;
use URI::Escape qw( uri_escape_utf8 );
use WWW::Keycloak::Diff;
use namespace::autoclean;

our $VERSION = '0.001';


has base_url => ( is => 'ro', isa => Str, required => 1 );
has realm    => ( is => 'ro', isa => Str, required => 1 );
has http     => ( is => 'ro', isa => Object, required => 1 );
has auth     => ( is => 'ro', isa => InstanceOf['Net::Async::Keycloak::Auth'], predicate => 'has_auth' );


sub diff_class { 'WWW::Keycloak::Diff' }

####  transport

sub realm_url { $_[0]->base_url.'/admin/realms/'.uri_escape_utf8( $_[0]->realm ) }

async sub call_f {
  my ( $self, $method, $path, $body ) = @_;
  my $url = $path =~ m{\A/admin/} ? $self->base_url.$path : $self->realm_url.$path;
  $self->validation_error_class->throw( message => 'the Admin API needs credentials: give username and password, client_id and client_secret, or token' )
    unless $self->has_auth;
  my %arg    = defined $body ? ( json => $body ) : ();
  my $bearer = await $self->auth->token_f;   # outside the eval: a failed login is not a refused token
  my $result = eval { await $self->send_request_f( $method, $url, %arg, bearer => $bearer ) };
  if ( my $error = $@ ) {
    die $error unless blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_unauthorized && $self->auth->renewable;
    $self->auth->invalidate($bearer);
    $result = await $self->send_request_f( $method, $url, %arg, bearer => await( $self->auth->token_f ) );
  }
  return $result;
}


async sub _data_f { return ( await $_[0]->call_f( @_[ 1 .. $#_ ] ) )->{data} }
async sub _done_f { await $_[0]->call_f( @_[ 1 .. $#_ ] ); return 1 }

async sub _create_f {
  my ( $self, $path, $body ) = @_;
  my $location = ( await $self->call_f( POST => $path, $body ) )->{location} // '';
  my ( $id ) = $location =~ m{/([^/]+)\z};
  Net::Async::Keycloak::Error->throw( message => 'POST '.$path.' created something but sent no Location header' ) unless defined $id;
  return $id;
}

sub _esc { uri_escape_utf8( $_[1] ) }

sub _query {
  my ( $self, %query ) = @_;
  return '' unless %query;
  return '?'.join '&', map { $self->_esc($_).'='.$self->_esc( $query{$_} ) } sort keys %query;
}

####  server and realm

sub server_info_f  { $_[0]->_data_f( GET => '/admin/serverinfo' ) }
sub get_realm_f    { $_[0]->_data_f( GET => '' ) }
sub update_realm_f { $_[0]->_done_f( PUT => '', $_[1] ) }
sub delete_realm_f { $_[0]->_done_f( DELETE => '' ) }

async sub create_realm_f {
  my ( $self, $rep ) = @_;
  await $self->call_f( POST => '/admin/realms', { realm => $self->realm, %{ $rep || {} } } );
  return $self->realm;
}

sub export_realm_f {
  my ( $self, %opt ) = @_;
  return $self->_data_f( POST => '/partial-export'.$self->_query(
    exportClients        => $opt{clients} ? 'true' : 'false',
    exportGroupsAndRoles => $opt{groups_and_roles} ? 'true' : 'false'
  ) );
}

sub partial_import_f {
  my ( $self, $rep, %opt ) = @_;
  return $self->fail_validation('partial_import needs a representation') unless ref $rep eq 'HASH';
  return $self->_data_f( POST => '/partialImport', { ifResourceExists => $opt{if_exists} // 'FAIL', %$rep } );
}

####  clients

sub list_clients_f  { my ( $self, %q ) = @_; $self->_data_f( GET => '/clients'.$self->_query(%q) ) }
sub get_client_f    { $_[0]->_data_f( GET => '/clients/'.$_[0]->_esc( $_[1] ) ) }
sub create_client_f { $_[0]->_create_f( '/clients', $_[1] ) }
sub update_client_f { $_[0]->_done_f( PUT => '/clients/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client_f { $_[0]->_done_f( DELETE => '/clients/'.$_[0]->_esc( $_[1] ) ) }

async sub find_client_f {
  my ( $self, $client_id ) = @_;
  my ( $client ) = grep { $_->{clientId} eq $client_id } @{ await $self->list_clients_f( clientId => $client_id ) };
  return $client;
}

sub get_client_secret_f        { $_[0]->_data_f( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub regenerate_client_secret_f { $_[0]->_data_f( POST => '/clients/'.$_[0]->_esc( $_[1] ).'/client-secret' ) }
sub get_service_account_user_f { $_[0]->_data_f( GET => '/clients/'.$_[0]->_esc( $_[1] ).'/service-account-user' ) }

####  client scopes

sub list_client_scopes_f  { $_[0]->_data_f( GET => '/client-scopes' ) }
sub get_client_scope_f    { $_[0]->_data_f( GET => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }
sub create_client_scope_f { $_[0]->_create_f( '/client-scopes', $_[1] ) }
sub update_client_scope_f { $_[0]->_done_f( PUT => '/client-scopes/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_client_scope_f { $_[0]->_done_f( DELETE => '/client-scopes/'.$_[0]->_esc( $_[1] ) ) }

async sub find_client_scope_f {
  my ( $self, $name ) = @_;
  my ( $scope ) = grep { $_->{name} eq $name } @{ await $self->list_client_scopes_f };
  return $scope;
}

sub add_default_client_scope_f {
  my ( $self, $client, $scope ) = @_;
  return $self->_done_f( PUT => '/clients/'.$self->_esc($client).'/default-client-scopes/'.$self->_esc($scope) );
}

sub add_realm_default_client_scope_f { $_[0]->_done_f( PUT => '/default-default-client-scopes/'.$_[0]->_esc( $_[1] ) ) }

####  protocol mappers

sub _mapper_path {
  my ( $self, $kind, $owner ) = @_;
  $self->validation_error_class->throw( message => 'protocol mappers belong to a client or a client_scope, not to '.( $kind // 'nothing' ) )
    unless defined $kind && ( $kind eq 'client' || $kind eq 'client_scope' );
  return ( $kind eq 'client' ? '/clients/' : '/client-scopes/' ).$self->_esc($owner).'/protocol-mappers/models';
}

async sub list_protocol_mappers_f  { my ( $self, $kind, $owner ) = @_; return await $self->_data_f( GET => $self->_mapper_path( $kind, $owner ) ) }
async sub create_protocol_mapper_f { my ( $self, $kind, $owner, $rep ) = @_; return await $self->_create_f( $self->_mapper_path( $kind, $owner ), $rep ) }

async sub update_protocol_mapper_f {
  my ( $self, $kind, $owner, $id, $rep ) = @_;
  return await $self->_done_f( PUT => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id), $rep );
}

async sub delete_protocol_mapper_f {
  my ( $self, $kind, $owner, $id ) = @_;
  return await $self->_done_f( DELETE => $self->_mapper_path( $kind, $owner ).'/'.$self->_esc($id) );
}

####  users

sub list_users_f  { my ( $self, %q ) = @_; $self->_data_f( GET => '/users'.$self->_query(%q) ) }
sub get_user_f    { $_[0]->_data_f( GET => '/users/'.$_[0]->_esc( $_[1] ) ) }
sub create_user_f { $_[0]->_create_f( '/users', $_[1] ) }
sub update_user_f { $_[0]->_done_f( PUT => '/users/'.$_[0]->_esc( $_[1] ), $_[2] ) }
sub delete_user_f { $_[0]->_done_f( DELETE => '/users/'.$_[0]->_esc( $_[1] ) ) }

async sub find_user_f {
  my ( $self, $username ) = @_;
  my ( $user ) = grep { lc $_->{username} eq lc $username } @{ await $self->list_users_f( username => $username, exact => 'true' ) };
  return $user;
}

sub set_password_f {
  my ( $self, $id, $password, %opt ) = @_;
  return $self->_done_f( PUT => '/users/'.$self->_esc($id).'/reset-password',
    { type => 'password', value => $password, temporary => $opt{temporary} ? \1 : \0 } );
}

sub list_credentials_f  { $_[0]->_data_f( GET => '/users/'.$_[0]->_esc( $_[1] ).'/credentials' ) }
sub delete_credential_f { $_[0]->_done_f( DELETE => '/users/'.$_[0]->_esc( $_[1] ).'/credentials/'.$_[0]->_esc( $_[2] ) ) }
sub list_sessions_f     { $_[0]->_data_f( GET => '/users/'.$_[0]->_esc( $_[1] ).'/sessions' ) }
sub logout_user_f       { $_[0]->_done_f( POST => '/users/'.$_[0]->_esc( $_[1] ).'/logout' ) }

####  authentication

sub list_flows_f              { $_[0]->_data_f( GET => '/authentication/flows' ) }
sub list_executions_f         { $_[0]->_data_f( GET => '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/executions' ) }
sub copy_flow_f               { $_[0]->_create_f( '/authentication/flows/'.$_[0]->_esc( $_[1] ).'/copy', { newName => $_[2] } ) }
sub get_execution_config_f    { $_[0]->_data_f( GET => '/authentication/config/'.$_[0]->_esc( $_[1] ) ) }
sub create_execution_config_f { $_[0]->_create_f( '/authentication/executions/'.$_[0]->_esc( $_[1] ).'/config', $_[2] ) }
sub update_execution_config_f {
  my ( $self, $id, $rep ) = @_;
  return $self->fail_validation('update_execution_config needs a representation') unless ref $rep eq 'HASH';
  return $self->_done_f( PUT => '/authentication/config/'.$self->_esc($id), { %$rep, id => $id } );
}
sub describe_authenticator_f  { $_[0]->_data_f( GET => '/authentication/config-description/'.$_[0]->_esc( $_[1] ) ) }


####  ensure

async sub _ensure_f {
  my ( $self, %arg ) = @_;
  my $current = await $arg{find}->();
  return { id => await( $arg{create}->() ), changed => 'created' } unless $current;
  my $changes = $self->diff_class->changes( $current, $arg{wanted} );
  return { id => $arg{id}->($current), changed => '' } unless %$changes;
  await $arg{update}->( $current, $changes );
  return { id => $arg{id}->($current), changed => 'updated' };
}

sub ensure_realm_f {
  my ( $self, %rep ) = @_;
  return $self->_ensure_f(
    wanted => \%rep,
    find   => sub {
      $self->get_realm_f->else( sub {
        my ( $error ) = @_;
        return Future->done(undef) if blessed $error && $error->isa('WWW::Keycloak::Error::API') && $error->is_not_found;
        return Future->fail($error);
      } );
    },
    create => sub { $self->create_realm_f( \%rep ) },
    update => sub { $self->update_realm_f( $_[1] ) },
    id     => sub { $_[0]->{realm} }
  );
}

sub ensure_client_f {
  my ( $self, %rep ) = @_;
  return $self->fail_validation('ensure_client needs a clientId') unless defined $rep{clientId};
  for my $ignored (qw( defaultClientScopes optionalClientScopes protocolMappers )) {
    return $self->fail_validation( 'ensure_client cannot set '.$ignored
      .': Keycloak ignores it when a client is updated; use add_default_client_scope or ensure_protocol_mapper' )
      if exists $rep{$ignored};
  }
  return $self->_ensure_f(
    wanted => \%rep,
    find   => sub { $self->find_client_f( $rep{clientId} ) },
    create => sub { $self->create_client_f( \%rep ) },
    update => sub { $self->update_client_f( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

sub ensure_client_scope_f {
  my ( $self, %rep ) = @_;
  return $self->fail_validation('ensure_client_scope needs a name') unless defined $rep{name};
  return $self->_ensure_f(
    wanted => \%rep,
    find   => sub { $self->find_client_scope_f( $rep{name} ) },
    create => sub { $self->create_client_scope_f( { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_client_scope_f( $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

async sub ensure_protocol_mapper_f {
  my ( $self, $kind, $owner_key, %rep ) = @_;
  $self->validation_error_class->throw( message => 'ensure_protocol_mapper needs a name' ) unless defined $rep{name};
  my $owner = $kind && $kind eq 'client' ? await( $self->find_client_f($owner_key) )
    : $kind && $kind eq 'client_scope' ? await( $self->find_client_scope_f($owner_key) )
    : $self->_mapper_path($kind);
  $self->validation_error_class->throw( message => 'ensure_protocol_mapper: no '.$kind.' '.$owner_key ) unless $owner;
  return await $self->_ensure_f(
    wanted => \%rep,
    find   => sub {
      $self->list_protocol_mappers_f( $kind, $owner->{id} )->then( sub {
        Future->done( ( grep { $_->{name} eq $rep{name} } @{ $_[0] } )[0] );
      } );
    },
    create => sub { $self->create_protocol_mapper_f( $kind, $owner->{id}, { protocol => 'openid-connect', %rep } ) },
    update => sub { $self->update_protocol_mapper_f( $kind, $owner->{id}, $_[0]{id}, { %{ $_[0] }, %{ $_[1] } } ) },
    id     => sub { $_[0]->{id} }
  );
}

sub ensure_user_f {
  my ( $self, %rep ) = @_;
  return $self->fail_validation('ensure_user needs a username') unless defined $rep{username};
  # Keycloak keeps user names and e-mail addresses in lower case
  my %compare = %rep;
  delete $compare{credentials};
  $compare{$_} = lc $compare{$_} for grep { defined $compare{$_} } qw( username email );
  # Keycloak keeps every user attribute as a list of strings
  $compare{attributes} = { map { $_ => ref $rep{attributes}{$_} eq 'ARRAY' ? $rep{attributes}{$_} : [ $rep{attributes}{$_} ] } keys %{ $rep{attributes} } }
    if ref $rep{attributes} eq 'HASH';
  return $self->_ensure_f(
    wanted => \%compare,
    find   => sub { $self->find_user_f( $rep{username} ) },
    create => sub { $self->create_user_f( \%rep ) },
    # the whole user: Keycloak's user profile drops fields a PUT with attributes does not name
    update => sub { $self->update_user_f( $_[0]{id}, $self->diff_class->merge( $_[0], $_[1] ) ) },
    id     => sub { $_[0]->{id} }
  );
}

async sub ensure_execution_config_f {
  my ( $self, %arg ) = @_;
  for (qw( flow authenticator config )) {
    $self->validation_error_class->throw( message => 'ensure_execution_config needs '.$_ ) unless defined $arg{$_};
  }
  my ( $execution ) = grep { ( $_->{providerId} // '' ) eq $arg{authenticator} } @{ await $self->list_executions_f( $arg{flow} ) };
  $self->validation_error_class->throw( message => 'flow "'.$arg{flow}.'" has no step '.$arg{authenticator} ) unless $execution;
  my $alias = $arg{alias} // $arg{flow}.' '.$arg{authenticator};
  return await $self->_ensure_f(
    wanted => { config => $arg{config} },
    find   => sub { $execution->{authenticationConfig} ? $self->get_execution_config_f( $execution->{authenticationConfig} ) : Future->done(undef) },
    create => sub { $self->create_execution_config_f( $execution->{id}, { alias => $alias, config => $arg{config} } ) },
    update => sub { $self->update_execution_config_f( $_[0]{id}, { alias => $_[0]{alias}, config => $arg{config} } ) },
    id     => sub { $_[0]->{id} }
  );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Keycloak::Admin - Keycloak Admin REST API for one realm, asynchronously, with idempotent ensure methods

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $admin = $kc->admin;

    my $client = await $admin->find_client_f('my-cli');
    my $r      = await $admin->ensure_client_f( clientId => 'my-cli', publicClient => \1 );

=head1 DESCRIPTION

The asynchronous L<WWW::Keycloak::Admin>: every method with C<_f>, returning a
future of what the sync method returns. The rules of the C<ensure_*_f> methods
are the same, and so is the comparison: both use L<WWW::Keycloak::Diff>.

=head2 base_url

=head2 realm

=head2 http

=head2 auth

As in L<WWW::Keycloak::Admin>, with a L<Net::Async::HTTP> as C<http> and a
L<Net::Async::Keycloak::Auth> as C<auth>.

=head2 call_f

    my $result = await $admin->call_f( GET => '/clients?clientId=x' );

As C<call> in L<WWW::Keycloak::Admin>.

=head2 server_info_f

=head2 get_realm_f

=head2 create_realm_f

=head2 update_realm_f

=head2 delete_realm_f

=head2 export_realm_f

=head2 partial_import_f

=head2 list_clients_f

=head2 find_client_f

=head2 get_client_f

=head2 create_client_f

=head2 update_client_f

=head2 delete_client_f

=head2 get_client_secret_f

=head2 regenerate_client_secret_f

=head2 get_service_account_user_f

=head2 list_client_scopes_f

=head2 find_client_scope_f

=head2 get_client_scope_f

=head2 create_client_scope_f

=head2 update_client_scope_f

=head2 delete_client_scope_f

=head2 add_default_client_scope_f

=head2 add_realm_default_client_scope_f

=head2 list_protocol_mappers_f

=head2 create_protocol_mapper_f

=head2 update_protocol_mapper_f

=head2 delete_protocol_mapper_f

=head2 list_users_f

=head2 find_user_f

=head2 get_user_f

=head2 create_user_f

=head2 update_user_f

=head2 delete_user_f

=head2 set_password_f

=head2 list_credentials_f

=head2 delete_credential_f

=head2 list_sessions_f

=head2 logout_user_f

=head2 list_flows_f

=head2 list_executions_f

=head2 copy_flow_f

=head2 get_execution_config_f

=head2 create_execution_config_f

=head2 update_execution_config_f

=head2 describe_authenticator_f

The methods of L<WWW::Keycloak::Admin> with the same name without C<_f>,
taking the same arguments and returning a future of the same result. A failure
is a failed future with a L<Net::Async::Keycloak::Error::API>.

=head2 ensure_realm_f

=head2 ensure_client_f

=head2 ensure_client_scope_f

=head2 ensure_protocol_mapper_f

=head2 ensure_user_f

=head2 ensure_execution_config_f

    my $r = await $admin->ensure_client_f( clientId => 'my-cli', publicClient => \1 );

As the C<ensure_*> methods of L<WWW::Keycloak::Admin>, with the same rules and
the same comparison, returning a future of C<< { id => ..., changed => ... } >>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-keycloak/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

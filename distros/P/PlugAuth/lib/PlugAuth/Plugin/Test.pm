package PlugAuth::Plugin::Test;

# ABSTRACT: Test Plugin server
our $VERSION = '0.38'; # VERSION

use strict;
use warnings;
use PlugAuth::Plugin::FlatAuth;
use PlugAuth::Plugin::FlatAuthz;
use Role::Tiny::With;
use Log::Log4perl qw( :easy );
use Fcntl qw( :flock );

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Refresh';
with 'PlugAuth::Role::Auth';
with 'PlugAuth::Role::Authz';

sub init
{
  my($self) = @_;
  $self->app->routes->route('/test/setup/reset')->post(sub {
  
    foreach my $filename (map { $self->global_config->{$_} } qw( group_file resource_file user_file ))
    {
      open my $fh, '+<', $filename;
      eval { flock $fh, LOCK_EX };
      WARN "cannot lock $filename - $@" if $@;
      seek $fh, 0, 0;
      truncate $fh, 0;
      close $fh;
      PlugAuth::Role::Flat->mark_changed($filename);
    }
    
    $self->real_auth->refresh;
    $self->real_authz->refresh;

    shift->render(text => 'ok');
  });
  $self->app->routes->route('/test/setup/basic')->post(sub {
    my $auth = $self->real_auth;
    $auth->create_user('primus', 'spark');
    $auth->create_user('optimus', 'matrix');
    $auth->refresh;
  
    my $authz = $self->real_authz;
    $authz->create_group('admin', 'primus');
    $authz->refresh;
    $authz->grant('admin', 'accounts', '/');
    $authz->grant('primus', 'accounts', '/');
    
    shift->render(text => 'ok');
  });
}

sub refresh
{
  my($self) = @_;
  $self->real_auth->refresh;
  $self->real_authz->refresh;
  1;
}

sub check_credentials        { shift->real_auth->check_credentials(@_) }
sub create_user              { shift->real_auth->create_user(@_) }
sub change_password          { shift->real_auth->change_password(@_) }
sub delete_user              { shift->real_auth->delete_user(@_) }
sub all_users                { shift->real_auth->all_users }
sub can_user_action_resource { shift->real_authz->can_user_action_resource(@_) }

sub match_resources { shift->real_authz->match_resources(@_) }
sub host_has_tag    { shift->real_authz->host_has_tag(@_) }
sub actions         { shift->real_authz->actions(@_) }
sub groups_for_user { shift->real_authz->groups_for_user(@_) }
sub all_groups      { shift->real_authz->all_groups(@_) }
sub users_in_group  { shift->real_authz->users_in_group(@_) }

sub create_group { shift->real_authz->create_group(@_) }
sub delete_group { shift->real_authz->delete_group(@_) }
sub grant        { shift->real_authz->grant(@_) }
sub revoke       { shift->real_authz->revoke(@_) }
sub granted      { shift->real_authz->granted(@_) }
sub update_group { shift->real_authz->update_group(@_) }

sub real_auth
{
  my($self) = @_;
  
  unless($self->{real_auth})
  {
    my $auth = $self->{real_auth} = new PlugAuth::Plugin::FlatAuth(
      Clustericious::Config->new({}),
      Clustericious::Config->new({}),
      $self->app
    );
  }
  
  return $self->{real_auth};
}

sub real_authz
{
  my($self) = @_;
  
  unless($self->{real_authz})
  {
    my $auth = $self->real_auth;
    my $authz = $self->{real_authz} = new PlugAuth::Plugin::FlatAuthz(
      Clustericious::Config->new({}),
      Clustericious::Config->new({}),
      $self->app
    );
  }
  
  return $self->{real_authz};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::Test - Test Plugin server

=head1 VERSION

version 0.38

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

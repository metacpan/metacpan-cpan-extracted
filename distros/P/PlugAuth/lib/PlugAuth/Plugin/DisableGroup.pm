package PlugAuth::Plugin::DisableGroup;

use strict;
use warnings;
use 5.010001;
use Role::Tiny::With;

# ABSTRACT: Disable accounts which belong to a group
our $VERSION = '0.39'; # VERSION


with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Auth';

sub init
{
  my($self) = @_;
  my $group = $self->{group} = $self->plugin_config->{group} // 'disabled';
  if($self->plugin_config->{disable_on_create})
  {
    $self->app->on(create_user => sub {
      my($app, $args) = @_;
      my $user = $args->{user};
      $app->authz->update_group($group, join(',', @{ $app->authz->users_in_group($group) }, $user))
    });
  }
}

sub check_credentials
{
  my($self, $user, $pass) = @_;
  my $groups = $self->app->authz->groups_for_user($user);
  return 0 unless $groups;
  return 0 if grep { lc($_) eq $self->{group} } @$groups;
  $self->deligate_check_credentials($user, $pass);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::DisableGroup - Disable accounts which belong to a group

=head1 VERSION

version 0.39

=head1 SYNOPSIS

In your PlugAuth.conf:

 ---
 plugins:
   - PlugAuth::Plugin::DisableGroup:
       # the default is "disabled"
       group: disabled
       # the default is to not create users as disabled
       disable_on_create: 0
   - PlugAuth::Plugin::FlatAuth: {}

=head1 DESCRIPTION

This plugin disables the authentication for a user when they are in a
specific group (the C<disabled> group if it is not specified in the
configuration file).

Trap for the unwary:

Note that you need to specify a real authentication to chain after 
this plugin (L<PlugAuth::Plugin::FlatAuth> is a good choice).  If
you don't then all authentication will fail.

=head1 OPTIONS

=head2 group

The name of the disabled group.  Defaults to "disabled".

=head2 disable_on_create

If set to true, it will disable all new accounts.  Defaults to false.

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

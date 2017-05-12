package PlugAuth::Plugin::ExampleAuth;

use strict;
use warnings;
use Role::Tiny::With;

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Auth';

# Note, while this is a useful example to show how to write
# an authentication plugin for PlugAuth, it is probably not
# useful as written for two reasons:
# 
#  1. Users created/modified/deleted will be lost when the
#     PlugAuth server terminates.
#  2. This plugin stores user/password data in non-shared 
#     memory, so if PlugAuth is run in a forked mode this
#     plugin will not work properly.  The obvious solution
#     to this would be to store user/password data in a file
#     or shared memory.

sub init
{
  my($self) = @_;
  $self->{user}->{primus}  = 'spark';
  $self->{user}->{optimus} = 'matrix';
}

sub check_credentials
{
  my($self, $user, $pass) = @_;
  return 0 unless defined $user && defined $pass;
  return 0 unless defined $self->{user}->{$user};
  ($self->{user}->{$user} eq $pass) ? 1 : 0;
}

sub all_users 
{
  my($self) = @_;
  keys %{ $self->{user} } 
}

sub create_user
{
  my($self, $user, $pass) = @_;
  return 0 if defined $self->{user}->{$user};
  $self->{user}->{$user} = $pass;
  1;
}

sub delete_user
{
  my($self, $user) = @_;
  return 0 unless defined $self->{user}->{$user};
  delete $self->{user}->{$user};
  1;
}

sub change_password
{
  my($self, $user, $pass) = @_;
  return 0 unless defined $self->{user}->{$user};
  $self->{user}->{$user} = $pass;
  1;
}

1;

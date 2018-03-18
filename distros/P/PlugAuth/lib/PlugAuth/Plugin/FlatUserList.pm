package PlugAuth::Plugin::FlatUserList;

# ABSTRACT: PlugAuth plugin that provides a user list without authentication.
our $VERSION = '0.39'; # VERSION


use strict;
use warnings;
use Role::Tiny::With;
use File::stat qw( stat );

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Auth';

sub init
{
  my($self) = @_;
  $self->{filename} = $self->plugin_config->user_list_file;
  $self->{mtime} = 0;
}


sub check_credentials 
{
  my($self, $user, $pass) = @_;
  return $self->deligate_check_credentials($user, $pass);
}


sub all_users
{
  my($self) = @_;
  my $mtime = stat($self->{filename})->mtime;
  if($mtime != $self->{mtime})
  {
    open(my $fh, '<', $self->{filename});
    my @list = grep !/^\s*$/, <$fh>;
    chomp @list;
    close $fh;
    $self->{mtime} = $mtime;
    $self->{list} = \@list;
  }
  return @{ $self->{list} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::FlatUserList - PlugAuth plugin that provides a user list without authentication.

=head1 VERSION

version 0.39

=head1 SYNOPSIS

In your PlugAuth.conf file:

 ---
 plugins:
   - PlugAuth::Plugin::FlatUserList:
       user_list_file: /path/to/user_list.txt
   - PlugAuth::Plugin::LDAP: {}
 ldap :
   server : ldap://1.2.3.4:389
   dn : uid=%s, ou=people, dc=users, dc=example, dc=com
   authoritative : 1

Then in /path/to/user_list.txt

 alice
 bob
 george
 ...

=head1 DESCRIPTION

This plugin provides a user list, stored as a flat file.  It just provides a user list,
no authentication.  All authentication requests are passed onto the next authentication
plugin in your configuration.  The intent of this plugin is to provide a user list for
authentication plugins which do not otherwise provide a user list (The above example
shows how to configure this plugin with the L<LDAP|PlugAuth::Plugin::LDAP> plugin as
an example).

The format of the user list is a simple text file, one line per user.  Do not use
spaces, comments, tabs or anything like that as they are not supported.  This plugin
does NOT support modifying the user list through the PlugAuth RESTful API.  You will
need to hand edit the user list to add and remove users.

L<PlugAuth> needs an accurate user list to compute the list of groups and to handle
authorization, as there is a special group for each user that contains exactly just
that user and has the same name as that user.

=head1 METHODS

=head2 $plugin-E<gt>check_credentials( $user, $pass )

Check if the username and password is a valid credentials.  This plugin just passes
the request on to the next authentication plugin without checking the username or 
password.

=head2 $plugin-E<gt>all_users

Returns the list of users in the user list file.

=head1 SEE ALSO

L<PlugAuth>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

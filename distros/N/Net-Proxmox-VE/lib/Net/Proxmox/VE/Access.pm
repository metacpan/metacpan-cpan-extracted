#!/bin/false
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
# PODNAME: Net::Proxmox::VE::Access
# ABSTRACT: Functions for the 'access' portion of the API

use strict;
use warnings;

package Net::Proxmox::VE::Access;
$Net::Proxmox::VE::Access::VERSION = '0.41';
use parent 'Exporter';

use Net::Proxmox::VE::Exception;

use JSON::MaybeXS qw(decode_json);

our @EXPORT = qw(
  access
  access_domains access_groups access_roles
  create_access_domains create_access_groups create_access_roles create_access_users
  delete_access_domains delete_access_groups delete_access_roles delete_access_users
  get_access_domains get_access_groups get_access_roles get_access_users
  update_access_domains update_access_groups update_access_roles update_access_users
  sync_access_domains
  get_access_acl update_access_acl
  update_access_password
);


my $BASEPATH = '/access';

sub access {

    my $self = shift or return;

    return $self->get($BASEPATH);

}


sub access_domains {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'domains' );

}


sub create_access_domains {

    my $self = shift or return;
    my @p    = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for create_access_domains()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for create_access_domains()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for create_access_domains()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $BASEPATH, 'domains', \%args );

}


sub get_access_domains {

    my $self = shift or return;

    my $realm = shift
      or
      Net::Proxmox::VE::Exception->throw('No realm for get_access_domains()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for get_access_domains()')
      if ref $realm;

    return $self->get( $BASEPATH, 'domains', $realm );

}


sub update_access_domains {

    my $self = shift or return;

    my $realm = shift
      or Net::Proxmox::VE::Exception->throw(
        'No realm provided for update_access_domains()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for update_access_domains()')
      if ref $realm;
    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for update_access_domains()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_access_domains()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_access_domains()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'domains', $realm, \%args );

}


sub delete_access_domains {

    my $self = shift or return;

    my $realm = shift
      or Net::Proxmox::VE::Exception->throw(
        'No realm provided for delete_access_domains()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for delete_access_domains()')
      if ref $realm;

    return $self->delete( $BASEPATH, 'domains', $realm );

}

###
#


sub sync_access_domains {

    my $self = shift or return;

    my $realm = shift
      or Net::Proxmox::VE::Exception->throw(
        'No realm provided for sync_access_groups()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for sync_access_groups()')
      if ref $realm;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for sync_access_domains()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for sync_access_domains()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for sync_access_domains()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $BASEPATH, 'domains', \%args );

}


sub access_groups {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'groups' );

}


sub create_access_groups {

    my $self = shift or return;
    my @p    = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for create_access_groups()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for create_access_groups()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for create_access_groups()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $BASEPATH, 'groups', \%args );

}


sub get_access_groups {

    my $self = shift or return;

    my $groupid = shift
      or
      Net::Proxmox::VE::Exception->throw('No groupid for get_access_groups()');
    Net::Proxmox::VE::Exception->throw(
        'groupid must be a scalar for get_access_groups()')
      if ref $groupid;

    return $self->get( $BASEPATH, 'groups', $groupid );

}


sub update_access_groups {

    my $self = shift or return;

    my $realm = shift
      or Net::Proxmox::VE::Exception->throw(
        'No realm provided for update_access_groups()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for update_access_groups()')
      if ref $realm;

    my @p = @_;

    Net::Proxmox::VE::Exception->throw(
        'No arguments for update_access_groups()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_access_groups()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_access_groups()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'groups', $realm, \%args );

}


sub delete_access_groups {

    my $self    = shift or return;
    my $groupid = shift
      or Net::Proxmox::VE::Exception->throw(
        'No argument given for delete_access_groups()');

    return $self->delete( $BASEPATH, 'groups', $groupid );

}


sub access_roles {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'roles' );

}


sub create_access_roles {

    my $self = shift or return;
    my @p    = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for create_access_roles()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for create_access_roles()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for create_access_roles()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $BASEPATH, 'roles', \%args );

}


sub get_access_roles {

    my $self = shift or return;

    my $roleid = shift
      or Net::Proxmox::VE::Exception->throw('No roleid for get_access_roles()');
    Net::Proxmox::VE::Exception->throw(
        'roleid must be a scalar for get_access_roles()')
      if ref $roleid;

    return $self->get( $BASEPATH, 'roles', $roleid );

}


sub update_access_roles {

    my $self  = shift or return;
    my $realm = shift
      or Net::Proxmox::VE::Exception->throw(
        'No realm provided for update_access_roles()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for update_access_roles()')
      if ref $realm;
    my @p = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for update_access_roles()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_access_roles()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_access_roles()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'roles', $realm, \%args );

}


sub delete_access_roles {

    my $self   = shift or return;
    my $roleid = shift
      or Net::Proxmox::VE::Exception->throw(
        'No argument given for delete_access_roles()');

    return $self->delete( $BASEPATH, 'roles', $roleid );

}


sub access_users {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'users' );

}


sub create_access_users {

    my $self = shift or return;
    my @p    = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for create_access_users()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for create_access_users()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for create_access_users()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $BASEPATH, 'users', \%args );

}


sub get_access_users {

    my $self = shift or return;

    my $userid = shift
      or Net::Proxmox::VE::Exception->throw('No userid for get_access_users()');
    Net::Proxmox::VE::Exception->throw(
        'userid must be a scalar for get_access_users()')
      if ref $userid;

    return $self->get( $BASEPATH, 'users', $userid );

}


sub update_access_users {

    my $self  = shift or return;
    my $realm = shift
      or Net::Proxmox::VE::Exception->throw(
        'No realm provided for update_access_users()');
    Net::Proxmox::VE::Exception->throw(
        'realm must be a scalar for update_access_users()')
      if ref $realm;
    my @p = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for update_access_users()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_access_users()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_access_users()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'users', $realm, \%args );

}


sub delete_access_users {

    my $self   = shift or return;
    my $userid = shift
      or Net::Proxmox::VE::Exception->throw(
        'No argument given for delete_access_users()');

    return $self->delete( $BASEPATH, 'users', $userid );

}


sub get_access_acl {

    my $self = shift or return;

    return $self->get( $BASEPATH, 'acl' );

}


sub update_access_acl {

    my $self = shift or return;
    my @p    = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for update_acl()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_acl()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_acl()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'acl', \%args );

}


sub update_access_password {

    my $self = shift or return;
    my @p    = @_;

    Net::Proxmox::VE::Exception->throw('No arguments for update_password()')
      unless @p;
    my %args;

    if ( @p == 1 ) {
        Net::Proxmox::VE::Exception->throw(
            'Single argument not a hash for update_password()')
          unless ref $p[0] eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        Net::Proxmox::VE::Exception->throw(
            'Odd number of arguments for update_password()')
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $BASEPATH, 'password', \%args );

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE::Access - Functions for the 'access' portion of the API

=head1 VERSION

version 0.41

=head1 SYNOPSIS

  # assuming $obj is a Net::Proxmox::VE object

  my @dir_index = $obj->access();

  my @domain_index = $obj->access_domains();
  my $domain = $obj->access_domains($realm);

=head1 METHODS

=head2 access

Without arguments, returns the 'Directory index'.

Note: Accessible by all authenticated users.

=head2 access_domains

Gets a list of access domains (aka the Authentication domain index)

  @pools = $obj->access_domains();

Note: Anyone can access that, because we need that list for the login box (before the user is authenticated).

No arguments are available.

A hash will be returned which will include the following:

=over 4

=item realm

String.

=item string

String.

=item comment

A comment. The GUI use this text when you select a domain (Realm) on the login window.

Optional.

=item tfa

Enum. Available options: yubico, oath

Optional.

=back

=head2 create_access_domains

Adds an authentication server. i.e. creates a new access domain

  $ok = $obj->create_access_domains( %args );
  $ok = $obj->create_access_domains( \%args );

I<%args> may items contain from the following list

=over 4

=item realm

String. The id of the authentication domain you wish to add, in pve-realm format. This is required.

=item type

Enum. This is the server type and is one of: ad, ldap, openid, pam, or pve

This is required.

=item base_dn

String. LDAP base domain name. Optional.

=item comment

String. This is a comment associated with the new domain, this is optional.

=item default

Boolean. Use this domain as the default. Optional.

=item domain

String. AD domain name. Optional.

=item port

Integer. Server port, user '0' if you want to use the default setting. Optional.

=item secure

Boolean. Use secure LDAPS protocol. Optional.

=item user_attr

String. LDAP user attribute name. Optional.

=back

=head2 get_access_domains

Gets a single access domain

  $ok = $obj->get_access_domains( $realm )

Where $realm is a string in pve-realm format

=head2 update_access_domains

Updates (sets) a access domain's data

  $ok = $obj->update_access_domains( $realm, %args );
  $ok = $obj->update_access_domains( $realm, \%args );

Where $realm is a string in pve-realm format

I<%args> may items contain from the following list

=over 4

=item base_dn

String. LDAP base domain name. Optional.

=item comment

String. This is a comment associated with the domain, this is optional.

=item default

Boolean. Use this domain as the default. Optional.

=item domain

String. AD domain name. Optional.

=item port

Integer. Server port, user '0' if you want to use the default setting. Optional.

=item secure

Boolean. Use secure LDAPS protocol. Optional.

=item user_attr

String. LDAP user attribute name. Optional.

=back

=head2 delete_access_domains

Deletes a single access domain

  $ok = $obj->delete_access_domains( $realm )

Where $realm is a string in pve-realm format

=head2 sync_access_domains

Syncs users and/or groups from the configured LDAP to user.cfg.

  $ok = $obj->sync_access_domains( $realm, %args );
  $ok = $obj->sync_access_domains( $realm, \%args );

NOTE: Synced groups will have the name 'name-$realm', so make sure those groups do not exist to prevent overwriting.

I<%args> may items contain from the following list

=over 4

=item realm

String. The id of the authentication domain you wish to add, in pve-realm format. This is required.

=item dry-run

Boolean. If set, does not write anything. Default 0

=item enable-new

Boolean. Enable newly synced users immediately. Default 1

=item remove-vanished

String. A semicolon-seperated list of things to remove when they or the user vanishes during a sync. The following values are possible: 'entry' removes the user/group when not returned from the sync. 'properties' removes the set properties on existing user/group that do not appear in the source (even custom ones). 'acl' removes acls when the user/group is not returned from the sync. Instead of a list it also can be 'none' (the default).

Format: ([acl];[properties];[entry]) | none

=item scope

Enum. Select what to sync.

Possible values: users, groups, both

=back

=head2 access_groups

Gets a list of access groups (aka the Group index)

  @pools = $obj->access_groups();

Note: The returned list is restricted to groups where you have 'User.Modify', 'Sys.Audit' or 'Group.Allocate' permissions on /access/groups/<<group>>.

=head2 create_access_groups

Creates a new access group

  $ok = $obj->create_access_groups( %args );
  $ok = $obj->create_access_groups( \%args );

I<%args> may items contain from the following list

=over 4

=item groupid

String. The id of the access group you wish to add, in pve-groupid format. This is required.

=item comment

String. This is a comment associated with the new group, this is optional.

=back

=head2 get_access_groups

Gets a single access group

  $ok = $obj->get_access_groups( $groupid )

Where I<$groupid> is a string in pve-groupid format

=head2 update_access_groups

Updates (sets) a access group's data

  $ok = $obj->update_access_groups( $groupid, %args );
  $ok = $obj->update_access_groups( $groupid, \%args );

Where I<$groupid> is a string in pve-groupid format

I<%args> may items contain from the following list

=over 4

=item comment

String. This is a comment associated with the group, this is optional.

=back

=head2 delete_access_groups

Deletes a single access group

  $ok = $obj->delete_access_groups( $groupid )

Where I<$groupid> is a string in pve-groupid format

=head2 access_roles

Gets a list of access roles (aka the Role index)

  @pools = $obj->access_roles();

Note: Accessible by all authententicated users.

=head2 create_access_roles

Creates a new access role

  $ok = $obj->create_access_roles( %args );
  $ok = $obj->create_access_roles( \%args );

I<%args> may items contain from the following list

=over 4

=item roleid

String. The id of the access role you wish to add, in pve-roleid format. This is required.

=item privs

String. A string in pve-string-list format. Optional.

=back

=head2 get_access_roles

Gets a single access role

  $ok = $obj->get_access_roles( $roleid )

Where I<$roleid> is a string in pve-roleid format

=head2 update_access_roles

Updates (sets) a access role's data

  $ok = $obj->update_access_roles( $roleid, %args );
  $ok = $obj->update_access_roles( $roleid, \%args );

Where I<$roleid> is a string in pve-roleid format

I<%args> may items contain from the following list

=over 4

=item privs

String. A string in pve-priv-list format, this is required.

=item append

Booelean. Append privileges to existing. Optional.

=back

=head2 delete_access_roles

Deletes a single access role

  $ok = $obj->delete_access_roles( $roleid )

Where I<$roleid> is a string in pve-roleid format

=head2 access_users

Gets a list of users (aka the User index)

  @pools = $obj->access_users();

Note: You need 'Realm.AllocateUser' on '/access/realm/<<realm>>' on the realm of user <<userid>>, and 'User.Modify' permissions to '/access/groups/<<group>>' for any group specified (or 'User.Modify' on '/access/groups' if you pass no groups.

=head2 create_access_users

Creates a new user

  $ok = $obj->create_access_users( %args );
  $ok = $obj->create_access_users( \%args );

I<%args> may items contain from the following list

=over 4

=item userid

String. The id of the user you wish to add, in pve-userid format. This is required.

=item comment

String. This is a comment associated with the new user, this is optional.

=item email

String. The users email address in email-opt format. Optional.

=item enable

Boolean. If the user is enabled where the default is to be enabled. Disable with a 0 value. Optional.

=item expire

Integer. Account expiration date in seconds since epoch. 0 means never expire. Optional.

=item firstname

String. Optional.

=item groups

String. A string in pve-groupid-list format. Optional.

=item lastname

String. Optional.

=item password

String. The users initial passowrd. Optional.

=back

=head2 get_access_users

Gets a single user

  $ok = $obj->get_access_users( $userid )

Where I<$userid> is a string in pve-userid format

=head2 update_access_users

Updates (sets) a user's configuration

  $ok = $obj->update_access_users( $userid, %args );
  $ok = $obj->update_access_users( $userid, \%args );

Where I<$userid> is a string in pve-userid format

I<%args> may items contain from the following list

=over 4

=item append

Boolean. Optional.

=item comment

String. This is a comment associated with the user, this is optional.

=item email

String. The users email address in email-opt format. Optional.

=item enable

Boolean. If the user is enabled where the default is to be enabled. Disable with a 0 value. Optional.

=item expire

Integer. Account expiration date in seconds since epoch. 0 means never expire. Optional.

=item firstname

String. Optional.

=item groups

String. A string in pve-groupid-list format. Optional.

=item lastname

String. Optional.

=back

=head2 delete_access_users

Deletes a single user

  $ok = $obj->delete_access_users( $userid )

Where I<$userid> is a string in pve-userid format

=head2 get_access_acl

The returned list is restricted to objects where you have rights to modify permissions

  $pool = $obj->get_access_acl();

Note: The returned list is restricted to objects where you have rights to modify permissions.

=head2 update_access_acl

Updates (sets) an acl's data

  $ok = $obj->update_access_acl( %args );
  $ok = $obj->update_access_acl( \%args );

I<%args> may items contain from the following list

=over 4

=item path

String. Access control path. Required.

=item roles

String. List of roles. Required.

=item delete

Boolean. Removes the access rather than adding it. Optional.

=item groups

String. List of groups. Optional.

=item propagate

Boolean. Allow to propagate (inherit) permissions. Optional.

=item users

String. List of users. Optional.

=back

=head2 update_access_password

Updates a users password

  $ok = $obj->update_password( %args );
  $ok = $obj->update_password( \%args );

Each user is allowed to change his own password. See proxmox api document for which permissions are needed to change the passwords of other people.

I<%args> may items contain from the following list

=over 4

=item password

String. The new password. Required.

=item userid

String. User ID. Required.

=back

Note: Each user is allowed to change his own password. A user can change the password of another user if he has 'Realm.AllocateUser' (on the realm of user <<userid>>) and 'User.Modify' permission on /access/groups/<<group>> on a group where user <<userid>> is member of.

=head1 SEE ALSO

L<Net::Proxmox::VE>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Dean Hamstad.

This is free software, licensed under:

  The MIT (X11) License

=cut

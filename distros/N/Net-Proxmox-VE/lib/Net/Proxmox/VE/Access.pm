#!/bin/false
# vim: softtabstop=2 tabstop=2 shiftwidth=2 ft=perl expandtab smarttab
# PODNAME: Net::Proxmox::VE::Access
# ABSTRACT: Functions for the 'access' portion of the API

use strict;
use warnings;

package Net::Proxmox::VE::Access;
$Net::Proxmox::VE::Access::VERSION = '0.37';
use parent 'Exporter';

use Carp qw( croak );

use JSON::MaybeXS qw(decode_json);

our @EXPORT =
  qw(
  access
  access_domains access_groups access_roles
  create_access_domains create_access_groups create_access_roles create_access_users
  delete_access_domains delete_access_groups delete_access_roles delete_access_users
  get_access_domains get_access_groups get_access_roles get_access_users
  update_access_domains update_access_groups update_access_roles update_access_users
  login check_login_ticket clear_login_ticket
  get_access_acl update_access_acl
  update_access_password
  );


my $base = '/access';

sub access {

    my $self = shift or return;

    return $self->get($base);

}


sub access_domains {

    my $self = shift or return;

    return $self->get( $base, 'domains' )

}


sub create_access_domains {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for create_access_domains()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for create_access_domains()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for create_access_domains()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $base, 'domains', \%args )

}


sub get_access_domains {

    my $self = shift or return;

    my $a = shift or croak 'No realm for get_access_domains()';
    croak 'realm must be a scalar for get_access_domains()' if ref $a;

    return $self->get( $base, 'domains', $a )

}


sub update_access_domains {

    my $self   = shift or return;
    my $realm = shift or croak 'No realm provided for update_access_domains()';
    croak 'realm must be a scalar for update_access_domains()' if ref $realm;
    my @p = @_;

    croak 'No arguments for update_access_domains()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_access_domains()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_access_domains()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, 'domains', $realm, \%args )

}


sub delete_access_domains {

    my $self = shift or return;
    my $a    = shift or croak 'No argument given for delete_access_domains()';

    return $self->delete( $base, 'domains', $a )

}


sub access_groups {

    my $self = shift or return;

    return $self->get( $base, 'groups' )

}


sub create_access_groups {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for create_access_groups()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for create_access_groups()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for create_access_groups()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $base, 'groups', \%args )

}


sub get_access_groups {

    my $self = shift or return;

    my $a = shift or croak 'No groupid for get_access_groups()';
    croak 'groupid must be a scalar for get_access_groups()' if ref $a;

    return $self->get( $base, 'groups', $a )

}


sub update_access_groups {

    my $self   = shift or return;
    my $realm = shift or croak 'No realm provided for update_access_groups()';
    croak 'realm must be a scalar for update_access_groups()' if ref $realm;
    my @p = @_;

    croak 'No arguments for update_access_groups()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_access_groups()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_access_groups()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, 'groups', $realm, \%args )

}


sub delete_access_groups {

    my $self = shift or return;
    my $a    = shift or croak 'No argument given for delete_access_groups()';

    return $self->delete( $base, 'groups', $a )

}



sub access_roles {

    my $self = shift or return;

    return $self->get( $base, 'roles' )

}


sub create_access_roles {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for create_access_roles()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for create_access_roles()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for create_access_roles()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $base, 'roles', \%args )

}


sub get_access_roles {

    my $self = shift or return;

    my $a = shift or croak 'No roleid for get_access_roles()';
    croak 'roleid must be a scalar for get_access_roles()' if ref $a;

    return $self->get( $base, 'roles', $a )

}


sub update_access_roles {

    my $self   = shift or return;
    my $realm = shift or croak 'No realm provided for update_access_roles()';
    croak 'realm must be a scalar for update_access_roles()' if ref $realm;
    my @p = @_;

    croak 'No arguments for update_access_roles()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_access_roles()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_access_roles()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, 'roles', $realm, \%args )

}


sub delete_access_roles {

    my $self = shift or return;
    my $a    = shift or croak 'No argument given for delete_access_roles()';

    return $self->delete( $base, 'roles', $a )

}



sub access_users {

    my $self = shift or return;

    return $self->get( $base, 'users' )

}


sub create_access_users {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for create_access_users()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for create_access_users()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for create_access_users()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->post( $base, 'users', \%args )

}


sub get_access_users {

    my $self = shift or return;

    my $a = shift or croak 'No userid for get_access_users()';
    croak 'userid must be a scalar for get_access_users()' if ref $a;

    return $self->get( $base, 'users', $a )

}


sub update_access_users {

    my $self   = shift or return;
    my $realm = shift or croak 'No realm provided for update_access_users()';
    croak 'realm must be a scalar for update_access_users()' if ref $realm;
    my @p = @_;

    croak 'No arguments for update_access_users()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_access_users()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_access_users()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, 'users', $realm, \%args )

}


sub delete_access_users {

    my $self = shift or return;
    my $a    = shift or croak 'No argument given for delete_access_users()';

    return $self->delete( $base, 'users', $a )

}


sub check_login_ticket {

    my $self = shift or return;

    if (   $self->{ticket}
        && ref $self->{ticket} eq 'HASH'
        && $self->{ticket}
        && $self->{ticket}->{ticket}
        && $self->{ticket}->{CSRFPreventionToken}
        && $self->{ticket}->{username} eq $self->{params}->{username} . '@'
        . $self->{params}->{realm}
        && $self->{ticket_timestamp}
        && ( $self->{ticket_timestamp} + $self->{ticket_life} ) > time() )
    {
        return 1;
    }
    else {
        $self->clear_login_ticket;
    }

    return

}


sub clear_login_ticket {

    my $self = shift or return;

    if ( $self->{ticket} or $self->{timestamp} ) {
        $self->{ticket}           = undef;
        $self->{ticket_timestamp} = undef;
        return 1;
    }

    return

}


sub get_access_acl {

    my $self = shift or return;

    return $self->get( $base, 'acl' );

}


sub login {
    my $self = shift or return;

    # Prepare login request
    my $url = $self->url_prefix . '/api2/json/access/ticket';

    # Perform login request
    my $request_time = time();
    my $response     = $self->{ua}->post(
        $url,
        {
            'username' => $self->{params}->{username} . '@'
              . $self->{params}->{realm},
            'password' => $self->{params}->{password},
        },
    );

    if ( $response->is_success ) {
        # my $content           = $response->decoded_content;
        my $login_ticket_data = decode_json( $response->decoded_content );
        $self->{ticket} = $login_ticket_data->{data};

        # We use request time as the time to get the json ticket is undetermined,
        # id rather have a ticket a few seconds shorter than have a ticket that incorrectly
        # says its valid for a couple more
        $self->{ticket_timestamp} = $request_time;
        print "DEBUG: login successful\n"
          if $self->{params}->{debug};
        return 1;
    }
    else {

        print "DEBUG: login not successful\n"
          if $self->{params}->{debug};
        print "DEBUG: " . $response->status_line . "\n"
          if $self->{params}->{debug};

    }

    return;
}


sub update_access_acl {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for update_acl()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_acl()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_acl()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, 'acl', \%args )

}


sub update_access_password {

    my $self = shift or return;
    my @p = @_;

    croak 'No arguments for update_password()' unless @p;
    my %args;

    if ( @p == 1 ) {
        croak 'Single argument not a hash for update_password()'
          unless ref $a eq 'HASH';
        %args = %{ $p[0] };
    }
    else {
        croak 'Odd number of arguments for update_password()'
          if ( scalar @p % 2 != 0 );
        %args = @p;
    }

    return $self->put( $base, 'password', \%args )

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Proxmox::VE::Access - Functions for the 'access' portion of the API

=head1 VERSION

version 0.37

=head1 SYNOPSIS

  # assuming $obj is a Net::Proxmox::VE object

  my @dir_index = $obj->access();

  my @domain_index = $obj->access_domains();
  my $domain = $obj->access_domains($realm);

=head1 METHODS

=head2 access

Without arguments, returns the 'Directory index':

Note: Accessible by all authententicated users.

=head2 access_domains

Gets a list of access domains (aka the Authentication domain index)

  @pools = $obj->access_domains();

Note: Anyone can access that, because we need that list for the login box (before the user is authenticated).

=head2 create_access_domains

Creates a new access domain

  $ok = $obj->create_access_domains( %args );
  $ok = $obj->create_access_domains( \%args );

I<%args> may items contain from the following list

=over 4

=item realm

String. The id of the authentication domain you wish to add, in pve-realm format. This is required.

=item type

Enum. This is the server type and is either 'ad' or 'ldap'. This is required.

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

  $ok = $obj->get_access_domains('realm')

realm is a string in pve-realm format

=head2 update_access_domains

Updates (sets) a access domain's data

  $ok = $obj->update_access_domains( 'realm', %args );
  $ok = $obj->update_access_domains( 'realm', \%args );

realm is a string in pve-realm format

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

  $ok = $obj->delete_access_domains('realm')

realm is a string in pve-realm format

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

  $ok = $obj->get_access_groups('groupid')

groupid is a string in pve-groupid format

=head2 update_access_groups

Updates (sets) a access group's data

  $ok = $obj->update_access_groups( 'groupid', %args );
  $ok = $obj->update_access_groups( 'groupid', \%args );

groupid is a string in pve-groupid format

I<%args> may items contain from the following list

=over 4

=item comment

String. This is a comment associated with the group, this is optional.

=back

=head2 delete_access_groups

Deletes a single access group

  $ok = $obj->delete_access_groups('groupid')

groupid is a string in pve-groupid format

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

  $ok = $obj->get_access_roles('roleid')

roleid is a string in pve-roleid format

=head2 update_access_roles

Updates (sets) a access role's data

  $ok = $obj->update_access_roles( 'roleid', %args );
  $ok = $obj->update_access_roles( 'roleid', \%args );

roleid is a string in pve-roleid format

I<%args> may items contain from the following list

=over 4

=item privs

String. A string in pve-priv-list format, this is required.

=item append

Booelean. Append privileges to existing. Optional.

=back

=head2 delete_access_roles

Deletes a single access role

  $ok = $obj->delete_access_roles('roleid')

roleid is a string in pve-roleid format

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

  $ok = $obj->get_access_users('userid')

userid is a string in pve-userid format

=head2 update_access_users

Updates (sets) a user's configuration

  $ok = $obj->update_access_users( 'userid', %args );
  $ok = $obj->update_access_users( 'userid', \%args );

userid is a string in pve-userid format

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

  $ok = $obj->delete_access_users('userid')

userid is a string in pve-userid format

=head2 check_login_ticket

Verifies if the objects login ticket is valid and not expired

Returns true if valid
Returns false and clears the the login ticket details inside the object if invalid

=head2 clear_login_ticket

Clears the login ticket inside the object

=head2 get_access_acl

The returned list is restricted to objects where you have rights to modify permissions

  $pool = $obj->get_access_acl();

Note: The returned list is restricted to objects where you have rights to modify permissions.

=head2 login

Initiates the log in to the PVE Server using JSON API, and potentially obtains an Access Ticket.

Returns true if success

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

Brendan Beveridge <brendan@nodeintegration.com.au>, Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Dean Hamstad.

This is free software, licensed under:

  The MIT (X11) License

=cut

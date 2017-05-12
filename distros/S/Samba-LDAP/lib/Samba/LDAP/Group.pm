package Samba::LDAP::Group;

# Returned by Perl::MinimumVersion 0.11
require 5.006;

use warnings;
use strict;
use Regexp::DefaultFlags;
use Readonly;
use Carp qw( croak carp );
use base qw(Samba::LDAP::Base);
use Samba::LDAP;

#use Samba::LDAP::User;
use List::MoreUtils qw( any );

our $VERSION = '0.05';

#
# Add Log::Log4perl to all our classes!!!!
#

# Our usage messages
Readonly my $ADD_TO_GROUPS_USAGE =>
  'Usage: add_to_groups( $username | HoA, Aref | HoA);';

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# is_group_member( $dn,$userid )
#
# Check that the user is a member of the group already
#------------------------------------------------------------------------

sub is_group_member {
    my $self     = shift;
    my $dn_group = shift;
    my $username = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_slave();

    my $mesg = $ldap->search(
        base   => $dn_group,
        scope  => 'sub',
        filter => "(|(memberUid=$username)(member=uid=$username,$self->{usersDN}))"
    );
    $mesg->code && die $mesg->error;

    return ( $mesg->count ne 0 );
}

#------------------------------------------------------------------------
# add_to_group( $group, $username)
#
# Add $username to LDAP group $group
#------------------------------------------------------------------------

sub add_to_group {
    my $self     = shift;
    my $group    = shift;
    my $username = shift;

    my $members = q{};
    my $dn_line = $self->_get_group_dn($group);

    if ( !defined( $self->_get_group_dn($group) ) ) {
        $self->error("group $group does not exist\n");
        die $self->error();
    }

    if ( !defined($dn_line) ) {
        $self->error("Can not find group DN\n");
        die $self->error();
    }

    ( my $dn = $dn_line ) =~ s{\A dn:}{};

    # Should have been checked earlier, but check again anyway
    my $user       = Samba::LDAP::User->new();
    my $valid_user = $user->is_unix_user($username);

    # Die if they are not
    if ( $valid_user == 1 ) {
        $self->error("User $username, is not even a user on this system\n");
        die $self->error();
    }

    # Now check if the user is already present in the group
    my $is_member = $self->is_group_member( $dn, $username );
    if ( $is_member == 1 ) {
        $self->error("User $username already member of the group $group\n");
        die $self->error();
    }
    else {

        # bind to a directory with dn and password
        # It does not matter if the user already exist, Net::LDAP will add the
        # user if he does not exist, and ignore him if his already in the
        # directory.
        my $ldap = Samba::LDAP->new();
        $ldap = $ldap->connect_ldap_master();
        my $modify =
          $ldap->modify( "$dn",
            changes => [ add => [ memberUid => $username ] ] );
        $modify->code && die "failed to modify entry: ", $modify->error;
        return 0;
    }

    return 1;
}

#------------------------------------------------------------------------
# add_to_groups( $groups_ref | HoA, Aref | HoA, $username )
#
# Pass in a list of groups for the user to be added to.
#------------------------------------------------------------------------

sub add_to_groups {
    my $self     = shift;
    my $groups   = shift;
    my $username = shift;

    # Required arguments
    my @required_args = ($groups);

    # Allow HoA for adding lots of users to groups next.
    #my $groups_ref = {
    #        admin => [ 'staff', 'directors', 'contractors', ],
    #        ghenry => [ 'web_team', 'finance', 'cleaners', ],
    #      };

    croak $ADD_TO_GROUPS_USAGE
      if any { !defined $_ } @required_args;

    # Dereference the hashref passed to us by add_user in
    # Samba::LDAP::User to get the Array, or take a Aref ;-)

    my @groups;
    if ( ref($groups) eq 'HASH' ) {
        for my $key ( keys %{$groups} ) {

            # Reminder: $key is our $username
            $self->add_to_group( $key, ${$groups}{$key} );
        }
        return;
    }

    elsif ( ref($groups) eq 'ARRAY' ) {
        @groups = @{$groups};
    }
    else {
        $self->error("Need a normal Array_Ref, $ADD_TO_GROUPS_USAGE");
        croak $self->error();
    }

    for my $group (@groups) {
        $self->add_to_group( $group, $username );
    }
    return 1;
}

#------------------------------------------------------------------------
# add_group()
#
# Description here
#------------------------------------------------------------------------

sub add_group {
    my $self = shift;
}

#------------------------------------------------------------------------
# show_group( $group )
#
# Lists the entries for that group
#------------------------------------------------------------------------

sub show_group {
    my $self  = shift;
    my $group = shift;

    croak "No group specified!" if !$group;

    return $self->_read_group($group);
}

#------------------------------------------------------------------------
# list_groups()
#
# Lists the entries for that group
#------------------------------------------------------------------------

sub list_groups {
    my $self = shift;
}

#------------------------------------------------------------------------
# delete_group( $group_name )
#
# Deletes group name from LDAP tree
#------------------------------------------------------------------------

sub delete_group {
    my $self  = shift;
    my $group = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_slave();

    my $dn_line = $self->_get_group_dn($group);
    ( my $dn = $dn_line ) =~ s{\A dn: [ ] }{};

    if ( !defined($dn_line) ) {
        $self->error("$group doesn't exist\n");
        return $self->error();
    }

    my $modify = $ldap->delete($dn);
    $modify->code && croak "Failed to delete group : ", $modify->error;

    # take down session
    $ldap->unbind;

    return "$group group deleted\n.";
}

#------------------------------------------------------------------------
# read_group_entry( $group )
#
# Return all posixGroup details
#------------------------------------------------------------------------

sub read_group_entry {
    my $self  = shift;
    my $group = shift;
    my $entry;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_slave();

    my $mesg = $ldap->search(
        base   => $self->{groupsdn},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixGroup)(cn=$group))"
    );

    $mesg->code && die $mesg->error;
    my $nb = $mesg->count;

    if ( $nb > 1 ) {
        $self->error("Error: $nb groups exist \"cn=$group\"\n");

        foreach $entry ( $mesg->all_entries ) {
            my $dn = $entry->dn;
            return $dn;
        }

        return $self->error();
    }
    else {
        $entry = $mesg->shift_entry();
    }
    return $entry;
}

#------------------------------------------------------------------------
# read_group_entry_gid( $group )
#
# Read the group number in the LDAP Directory
#------------------------------------------------------------------------

sub read_group_entry_gid {
    my $self  = shift;
    my $group = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master();

    my $mesg = $ldap->search(    # perform a search
        base   => $self->{groupsdn},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixGroup)(gidNumber=$group))"
    );

    $mesg->code && die $mesg->error;
    my $entry = $mesg->shift_entry();
    return $entry;
}

#------------------------------------------------------------------------
# find_groups( $username )
#
# Find the groups that $username belongs to
#------------------------------------------------------------------------

sub find_groups {
    my $self   = shift;
    my $user   = shift;
    my @groups = ();

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master();

    # Everything apart from Open-xchange uses memberUid, OX uses
    # member, so we do 2 searches
    my $mesg = $ldap->search(
        base   => $self->{groupsdn},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixGroup)(memberUid=$user))"
    );
    $mesg->code && die $mesg->error;

    my $entry;
    while ( $entry = $mesg->shift_entry() ) {
        push( @groups, scalar( $entry->get_value('cn') ) );
    }

    # OX Search
    my $userdn = "uid=$user,$self->{usersdn}";
    my $mesg2  = $ldap->search(
        base   => $self->{suffix},
        scope  => 'sub',
        filter => "(&(objectclass=groupOfNames)(member=$userdn))"
    );
    $mesg2->code && die $mesg2->error;

    my $entry2;
    while ( $entry2 = $mesg2->shift_entry() ) {
        push( @groups, scalar( $entry2->get_value('cn') ) );
    }

    return (@groups);
}

#------------------------------------------------------------------------
# parse_group( $userGidNumber )
#
# Check the group is either a name or number
#------------------------------------------------------------------------

sub parse_group {
    my $self          = shift;
    my $userGidNumber = shift;

    if ( $userGidNumber =~ /[^\d]/ ) {
        my $gname  = $userGidNumber;
        my $gidnum = getgrnam($gname);
        if ( $gidnum !~ /\d+/ ) {
            return -1;
        }
        else {
            $userGidNumber = $gidnum;
        }
    }
    elsif ( !defined( getgrgid($userGidNumber) ) ) {
        return -2;
    }
    return $userGidNumber;
}

#------------------------------------------------------------------------
# remove_from_group( $group, $username )
#
# Remove the user from $group
#------------------------------------------------------------------------

sub remove_from_group {
    my $self  = shift;
    my $group = shift;
    my $user  = shift;

    my $members = q{};

    my $grp_line = $self->_get_group_dn($group);
    if ( !defined($grp_line) ) {
        return 0;
    }

    ( my $dn = $grp_line ) =~ s{\A dn: [ ] }{};

    # we test if the user exist in the group
    my $is_member = $self->is_group_member( $dn, $user );

    if ( $is_member == 1 ) {

        # delete only the user from the group
        my $ldap = Samba::LDAP->new();
        $ldap = $ldap->connect_ldap_master();
        my $modify = $ldap->modify(
            "$dn",
            changes => [
                delete => [
                    memberUid => ["$user"],
                    member    => ["uid=$user,$self->{usersdn}"],
                ],
            ]
        );
        $modify->code && die "failed to delete entry: ", $modify->error;
    }
    return 1;
}

#========================================================================
#                         -- PRIVATE METHODS --
#========================================================================

#------------------------------------------------------------------------
# _get_group_dn( $group )
#
# Searches for a groups distinguised name
#------------------------------------------------------------------------

sub _get_group_dn {
    my $self  = shift;
    my $group = shift;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master();

    if ( $group =~ /\A \d+ \z/ ) {
        $self->{filter} =
          "(&(objectclass=posixGroup)(|(cn=$group)(gidNumber=$group)))";
    }
    else {
        $self->{filter} = "(&(objectclass=posixGroup)(cn=$group))";
    }

    my $mesg = $ldap->search(
        base   => $self->{groupsdn},
        scope  => $self->{scope},
        filter => $self->{filter},
    );
    $mesg->code && croak $mesg->error;

    for my $entry ( $mesg->all_entries ) {
        $self->{dn} = $entry->dn;
    }

    # For OX AddressAdmins search
    my $mesg2  = $ldap->search(
        base   => $self->{suffix},
        scope  => $self->{scope},
        filter => "(&(objectclass=groupOfNames)(cn=$group))"
    );
    $mesg2->code && die $mesg2->error;

    for my $entry ( $mesg2->all_entries ) {
        $self->{dn} = $entry->dn;
    }

    if ( !$self->{dn} ) {
        croak "Can not find $group Group";
    }

    my $dn = $self->{dn};
    chomp($dn);

    $dn = "dn: " . $dn;

    return $dn;
}

#------------------------------------------------------------------------
# _read_group( $group )
#
# Search for members of a group
#------------------------------------------------------------------------

sub _read_group {
    my $self  = shift;
    my $group = shift;

    my $ldap_slave = Samba::LDAP->new();
    $ldap_slave = $ldap_slave->connect_ldap_slave();

    my $mesg = $ldap_slave->search(
        base   => $self->{groupsdn},
        scope  => $self->{scope},
        filter => "(&(objectclass=posixGroup)(cn=$group))"
    );
    $mesg->code && croak $mesg->error;

    my $lines = '';
    for my $entry ( $mesg->all_entries ) {
        $lines .= "dn: " . $entry->dn . "\n";
        for my $attr ( $entry->attributes ) {
            {
                $lines .=
                  $attr . ": " . join( ',', $entry->get_value($attr) ) . "\n";
            }
        }
    }

    # take down session
    $ldap_slave->unbind;

    chomp $lines;
    if ( $lines eq '' ) {
        return undef;
    }

    return $lines;
}

1;    # Magic true value required at end of module

__END__

=head1 NAME

Samba::LDAP::Group - Manipulate Samba LDAP Groups


=head1 VERSION

This document describes Samba::LDAP::Group version 0.05


=head1 SYNOPSIS

    use Carp;
    use Samba::LDAP::Group;

    my $group = Samba::LDAP::Group->new()
        or croak "Can't create object\n";
    

=head1 DESCRIPTION

Various methods to add, delete, modify and show Samba
LDAP Groups

B<DEVELOPER RELEASE!>

B<BE WARNED> - Not yet complete and neither are the docs!


=head1 INTERFACE 

=head2 new

Create a new L<Samba::LDAP::Group> object

=head2 add_group

Not complete.

=head2 add_to_group

Add $username to LDAP group $group

    my $result = $group->add_to_group( $group, $username);
    print "$username added to $group\n" if $result;

=head2 add_to_groups

Pass in a list of groups for the user or users to be added to.

For one user:

    my $groups_aref = [ 'staff', 'directors', 'contractors', ];

    my $result = $group->add_to_groups( $groups_aref, $username  );
    print "$username added to groups\n" if $result;

List of users and groups:

    my $groups_ref = {
                        admin => [ 'staff', 'directors', 'contractors', ],
                        ghenry => [ 'web_team', 'finance', 'cleaners', ],
                     };

    my $result = $group->add_to_groups( $group_ref );
    print "Added to groups\n" if $result;


=head2 find_groups

Find the groups that $username belongs to. Returns an Array of groups.

    my @groups = $group->find_groups( $username );
    print "@groups";

=head2 delete_group

Deletes group name from LDAP tree

    my $delete_result = $group->delete_group( $group_name );
    print "$delete_result";

=head2 remove_from_group

Remove the user from $group. Removes C<memberUid> and C<member> entries
    
    my $result = $group->remove_from_group( $group, $username )
    print "$group removed\n" if $result;

=head2 show_group

Lists the entries for that group

    my $group_info = $group->show_group( $group );
    print "$group_info\n";

=head2 list_groups

Not complete.

=head2 parse_group

Check the group is either a name or number.

    my $result = $group->parse_group( $userGidNumber );

Not complete.

=head2 is_group_member

Check that the user is a member of the group already

    my $result = $self->is_group_member( $dn,$userid );
    print "$userid is a member of $dn\n" if $result;


=head2 read_group_entry

Return all posixGroup details. Similar to L<show_group> and will be
re-organised later

    my $group_info = $group->read_group_entry( $group );
    print "$group_info\n";

Utility method.

=head2 read_group_entry_gid

Read the group number in the LDAP Directory.

    my $group_number = $group->read_group_entry_gid( $group );
    print $group_number\n";

Utility method.

=head1 DIAGNOSTICS

None yet.


=head1 CONFIGURATION AND ENVIRONMENT

Samba::LDAP::Group requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Carp>,
L<Regexp::DefaultFlags>,
L<Readonly> and
L<List::MoreUtils>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-samba-ldap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gavin Henry  C<< <ghenry@suretecsystems.com> >>


=head1 ACKNOWLEDGEMENTS

IDEALX for original scripts.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2001-2002 IDEALX - Original smbldap-tools

Copyright (c) 2006, Suretec Systems Ltd. - Gavin Henry
C<< <ghenry@suretecsystems.com> >>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. See L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

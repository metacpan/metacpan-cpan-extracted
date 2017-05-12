package Solstice::Subgroup;

# $Id: Group.pm 2253 2005-05-18 22:06:27Z mcrawfor $

=head1 NAME

Solstice::Subgroup - Manages subsets of people.

=head1 SYNOPSIS

  # See Solstice::Group
  #   This disables subgroup management, and classlists but is otherwise the same.

=head1 DESCRIPTION

Manages sets of people, who are a subset of a specific group.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Group);

use Solstice::Database;
use Solstice::Factory::Person;
use Solstice::ImplementationManager;

our ($VERSION) = ('$Revision: 2253 $' =~ /^\$Revision:\s*([\d.]*)/);
use constant TRUE  => 1;
use constant FALSE => 0;

our $id_creation_counter = 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new()
=item new($group_id)
=cut

sub new {
    my $obj = shift;
    my $input = shift;
    
    my $self = $obj->SUPER::new($input);

    return unless defined $self;
    
    unless (defined $input) {
        # This is a new subgroup, which is unsaved.  We need to be able to track it, 
        # So we'll give it a name that should be unique across all hosts...
        # If we're offline this will be null, and that's OK.
        my $host = $ENV{'SERVER_ADDR'} || '';
        $host =~ s/\./_/g;
        $self->_setID('unsaved_'.$$.'_'.$host.'_'.$id_creation_counter);
        $id_creation_counter++;
    }
    
    return $self;
}

=item clone()

=cut

sub clone {
    my $self = shift;

    my $clone = Solstice::Subgroup->new();
    $clone->setName($self->getName());
    $clone->addMembers($self->getMembers());

    for my $subgroup (@{$self->getSubgroups()->getAll()}) {
        $clone->addSubgroup($subgroup->clone());
    }
        
    return $clone;
}

=item delete()

=cut

sub delete {
    my $self = shift;

    return FALSE unless defined $self->getID();

    # Use Solstice::ImplementationManager to inform tools that this group
    # has been deleted
    my $impl_manager = Solstice::ImplementationManager->new();
    my $tool_list = $impl_manager->createList({
        method => 'subgroupDeleted',
        args   => [$self],
    });
    
    my $db = Solstice::Database->new();
    my $id = $self->getID();

    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->writeQuery('DELETE FROM '.$db_name.'.Subgroup WHERE subgroup_id = ?', $id);
    $db->writeQuery('DELETE FROM '.$db_name.'.PeopleInSubgroup WHERE subgroup_id = ?', $id);

    for my $subgroup (@{$self->getSubgroups()->getAll()}) {
        $subgroup->delete();
    }
    
    return TRUE;
}

=item store()

Saves the group to the data store.  Returns TRUE on success, FALSE otherwise.  Saving will fail if the following values are not defined: name, creator, and creating application.

=cut

sub store {
    my $self = shift;

    $self->_initializeMembers() unless $self->{'_initialized_members'};
    $self->_initializeSubgroups() unless $self->{'_initialized_subgroups'};
    
    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();
    
    my $id = $self->getID();

    my $name = $self->getName();
    
    if (defined $id and $id =~ /^\d+$/) {
    
        $db->writeQuery('UPDATE '.$db_name.'.Subgroup
        SET name=?, date_modified=NOW()
        WHERE subgroup_id = ?',
        $name, $id);
    }
    else {
        $db->writeQuery('INSERT INTO '.$db_name.'.Subgroup
        (name, date_modified, date_created)
        VALUES (?, NOW(), NOW())', $name);

        $id = $db->getLastInsertID();
        $self->_setID($id);
    }
    
    # We should probably come up with a better way of doing this... deleting everyone and readding is a bit crude.
    # XXX - make this smarter
    my $person_insert;
    my @person_data;
    foreach my $person_id (keys %{$self->{'_member_people'}}) {
        $person_insert .= "(?, ?),";
        push @person_data, $person_id;
        push @person_data, $id;
    }

    $db->writeQuery('DELETE FROM '.$db_name.'.PeopleInSubgroup WHERE subgroup_id = ?', $id);
    if (defined $person_insert and $person_insert) {
        chop $person_insert;
        $db->writeQuery('INSERT INTO '.$db_name.'.PeopleInSubgroup (person_id, subgroup_id) VALUES '.$person_insert, @person_data);
    }

    my $subgroup_insert = '';
    my @subgroup_data;
    
    foreach my $subgroup_id (keys %{$self->{'_subgroups'}}) {
        my $subgroup = $self->{'_subgroups'}->{$subgroup_id};
        $subgroup->store();

        my $new_subgroup_id = $subgroup->getID();
        if ($new_subgroup_id ne $subgroup_id) {
            delete $self->{'_subgroups'}->{$subgroup_id};
            $self->{'_subgroups'}->{$new_subgroup_id} = $subgroup;
        }
        $subgroup_insert .= "(NULL, ?, ?),";
        push @subgroup_data, $id;
        push @subgroup_data, $new_subgroup_id;
    }
    chop $subgroup_insert;
    
    $db->writeQuery('DELETE FROM '.$db_name.'.SubgroupsInSubgroup WHERE parent_subgroup_id = ?', $id);
    if ($subgroup_insert) {
        $db->writeQuery('INSERT INTO '.$db_name.'.SubgroupsInSubgroup VALUES '.$subgroup_insert, @subgroup_data);
    }
    
    for my $subgroup_id (keys %{$self->{'_removed_subgroups'}}) {
        my $subgroup = $self->{'_subgroups'}->{$subgroup_id};
        $subgroup->delete();
    }
    $self->{'_removed_subgroups'} = undef;
    
    # Use Solstice::ImplementationManager to inform tools that subgroup has been modified
    my $impl_manager = Solstice::ImplementationManager->new();
    my $tool_list = $impl_manager->createList({
        method => 'subgroupModified',
        args   => [$self],
    });

    return TRUE;
}

=item getCreationDate()

Returns a Solstice::DateTime object, representing the date the group was first added to the data store.  Returns undef if the group has never been saved to the data store.

=item _setCreationDate($date)

Sets the creation date of the group.  Should only be set on retrieval from the data store.

=item getModificationDate()

Returns a Solstice::DateTime object, representing when the group was last modified in the data store.  Returns undef if the group has never been saved to the data store.

=item _setModificationDate($date)

Sets the modification date of the group.  Should only be set on retrieval from the data store.


=item getMembers()

Returns a Solstice::List, containing Solstice::Person::<X> objects.  This list constists of all members of the groups, excluding member groups, or people who are in LDAP groups.

=item getMemberCount()

Returns the number of members for the group.

=item isMember($person)

Returns TRUE if the given person is a member of this group, recursively, FALSE otherwise.  

=item addMember($person)

Adds the given person object to the group.  A person can only be added to a group once, though multiple adds will not result in an error being raised.

=item removeMember($person)

Removes the given person from the group.  This only removes the user from the group itself, it does not traverse into member groups, or modify any entries for an LDAP group.

=item getAllMembers()

Returns a Solstice::List, containing all members of the groups, including members of member groups, and members of LDAP groups.

=cut

=back

=head2 Private Methods

=over 4

=cut

=item _initFromHash ($hash_ref)
=cut

sub _initFromHash {
    my $self = shift;
    my $input = shift;

    $self->{'_initialized_subgroups'} = FALSE;
    $self->{'_initialized_members'} = FALSE;
    
    $self->_setID($input->{'id'});
    $self->setName($input->{'name'});
    $self->_setModificationDate($input->{'modification_date'});
    $self->_setCreationDate($input->{'creation_date'});
    $self->setRootGroupID($input->{'root_group_id'});

    return TRUE;
}

=item _initMin($group_id)

Initializes the minimum amount of data about the group as it can.  Loads no member groups, subgroups, people, or class lists.

=cut

sub _initMin {
    my $self = shift;
    my $input = shift;

    return FALSE unless $self->isValidInteger($input);

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery('SELECT
    s.subgroup_id, s.name, s.date_created, s.date_modified, sig.parent_group_id
    FROM '.$db_name.'.Subgroup AS s, '.$db_name.'.SubgroupsInGroup AS sig
    WHERE s.subgroup_id = sig.subgroup_id AND s.subgroup_id=?', $input);
    
    my $data = $db->fetchRow();

    my $subgroup_id = $data->{'subgroup_id'};
    my $parent_id   = $data->{'parent_group_id'};
    
    if (!defined $subgroup_id) {
        $db->readQuery('SELECT
        s.subgroup_id, s.name, s.date_created, s.date_modified, sig.parent_subgroup_id
        FROM '.$db_name.'.Subgroup AS s, '.$db_name.'.SubgroupsInSubgroup AS sig
        WHERE s.subgroup_id = sig.subgroup_id AND s.subgroup_id=?', $input);
        
        $data = $db->fetchRow();
        $subgroup_id = $data->{'subgroup_id'};
        $parent_id   = $data->{'parent_subgroup_id'};
    }
    
    return FALSE unless defined $subgroup_id;

    $self->{'_initialized_subgroups'} = FALSE;
    $self->{'_initialized_members'} = FALSE;
    
    $self->_setID($subgroup_id);
    $self->setName($data->{'name'});
    $self->_setModificationDate(Solstice::DateTime->new($data->{'date_modified'}));
    $self->_setCreationDate(Solstice::DateTime->new($data->{'date_created'}));
    $self->setRootGroupID($parent_id);

    return TRUE;
}

=item _initializeMembers()

Goes to the data store to retrive the list of members for this group.

=cut

sub _initializeMembers {
    my $self = shift;

    return FALSE unless defined $self->getID();

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery('SELECT person_id 
    FROM '.$db_name.'.PeopleInSubgroup
    WHERE subgroup_id = ?', $self->getID());
    
    my @member_ids;
    while (my $data = $db->fetchRow()) {
        push @member_ids, $data->{'person_id'}; 
    }

    my $person_factory = Solstice::Factory::Person->new();
    my $people = $person_factory->createByIDs(\@member_ids)->getAll();
    
    $self->{'_member_people'} = {};
    for my $person (@$people) {
        $self->{'_member_people'}->{$person->getID()} = $person;
    }

    return $self->{'_initialized_members'} = TRUE;
}

=item _initializeOwners()

=cut

sub _initializeOwners {
    return TRUE;
}

=item _initializeMemberGroups()

=cut

sub _initializeMemberGroups {
    return TRUE;
}

=item _initializeRemoteGroups()

=cut

sub _initializeRemoteGroups {
    return TRUE;
}

=item _initializeSubgroups()

Goes to the data store to retrieve the list of subgroups for this group.

=cut

sub _initializeSubgroups {
    my $self = shift;

    return FALSE unless defined $self->getID();

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery('SELECT subgroup_id
    FROM '.$db_name.'.SubgroupsInSubgroup
    WHERE parent_subgroup_id = ?', $self->getID());
    
    $self->{'_subgroups'} = {};
    while (my $data = $db->fetchRow()) {
        my $subgroup = Solstice::Subgroup->new($data->{'subgroup_id'});
        if (defined $subgroup) {
            $self->{'_subgroups'}->{$data->{'subgroup_id'}} = $subgroup;
        }
    }

    return $self->{'_initialized_subgroups'} = TRUE;    
}

=item _getAllMembers($seen_group_hash)

A private method for recursing through groups, getting membership lists.

=cut

sub _getAllMembers {
    my $self = shift;
    my $seen_groups = shift;
    $seen_groups = {} unless defined $seen_groups;

    my $group_id = $self->getID();
    return {} unless defined $group_id;

    $seen_groups->{$group_id} = TRUE;

    # Make sure we have the data we need to proceed...
    $self->_initializeMembers() unless $self->{'_initialized_members'};
    
    return { map {%$_} $self->{'_member_people'} };
}

=item _populateMemberHash(\%member_hash)

Function that builds a hash of group members

=cut

sub _populateMemberHash {
    my $self = shift;
    my $member_hash = shift;

    if ($self->{'_initialized_members'}) {
        for my $person_id (keys %{$self->{'_member_people'}}) {
            $member_hash->{$person_id} = TRUE;
        }
    } else {
        $self->_populateDBMemberHash($member_hash);
    }
    return $member_hash;
}

=item _populateDBMemberHash(\%member_hash)

=cut

sub _populateDBMemberHash {
    my $self = shift;
    my $member_hash = shift;

    return $member_hash unless defined $self->getID();

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery('SELECT DISTINCT person_id
    FROM '.$db_name.'.PeopleInSubgroup
    WHERE subgroup_id = ?', $self->getID());

    while (my $data = $db->fetchRow()) {
        $member_hash->{$data->{'person_id'}} = TRUE;
    }

    return $member_hash;
}

=item _getAccessorDefinition()

Returns the array_ref that creates the basic accessors of Solstice::Group.

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Name',
            key  => '_name',
            type => 'String',
        },
        {
            name => 'RootGroupID',
            key  => '_root_group_id',
            type => 'Integer',
        }
    ];
}

1;

__END__

=back

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $



=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut

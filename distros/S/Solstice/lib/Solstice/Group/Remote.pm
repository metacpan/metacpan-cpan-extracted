package Solstice::Group::Remote;

# $Id: Remote.pm 2253 2005-05-18 22:06:27Z mcrawfor $

=head1 NAME

Solstice::Group::Remote - Model of groups who sync from a remote source.

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Group);

use Solstice::List;
use Solstice::Factory::Person;
use Solstice::Database;
use Solstice::DateTime;

use Carp qw(cluck);

our ($VERSION) = ('$Revision: 2253 $' =~ /^\$Revision:\s*([\d.]*)/);

use constant TRUE    => 1;
use constant FALSE   => 0;
use constant SUCCESS => 1;
use constant FAIL    => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new($input)

=cut

sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
}

=item clone()
=cut

sub clone {
    my $self = shift;
    cluck "clone(): Not implemented";
    return FAIL;
}    

=item delete()
=cut

sub delete {
    my $self = shift;
    cluck "delete(): Not implemented";
    return FAIL;
}

=item reconcile()
=cut

sub reconcile {
    my $self = shift;
    my $list = shift;
    
    unless ($self->isValidList($list)) {
        cluck 'reconcile(): requires a Solstice::List';
        return FAIL;
    }

    $self->SUPER::removeAllMembers();

    my $iterator = $list->iterator();
    while ($iterator->hasNext()) {
        return FALSE unless $self->SUPER::addMember($iterator->next());
    }

    $self->{'_is_reconciliation'} = TRUE;
    $self->{'_tainted_members'}   = TRUE;

    # Make sure we don't initialize group membership on store, otherwise
    # people who leave the remote group won't actually leave.
    $self->{'_initialized_members'} = TRUE;
    return SUCCESS;
}

=item store()
=cut

sub store {
    my $self = shift;

    return SUCCESS unless $self->{'_tainted_members'};
    
    # Not sure this is needed if we're tainted...
    $self->_initializeMembers() unless $self->{'_initialized_members'};
    
    my $db = Solstice::Database->new();    
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my $id = $self->getID();
    if (defined $id) {
        if ($self->{'_is_reconciliation'}) {
            $db->writeQuery('UPDATE '.$db_name.'.RemoteGroup SET date_reconciled = NOW() WHERE remote_group_id = ?',$id);
            $self->{'_is_reconciliation'} = FALSE;
        }
    } else {
        $db->readQuery('SELECT remote_group_source_id FROM '.$db_name.'.RemoteGroupSource WHERE package = ?',ref($self));
        my $remote_source_id = $db->fetchRow()->{'remote_group_source_id'}; 
    
        my $remote_key = $self->getRemoteKey();

        $db->readQuery('SELECT remote_group_id from '.$db_name.'.RemoteGroup where remote_key=? AND remote_group_source_id=?',$remote_key, $remote_source_id);
        
        $id = $db->fetchRow()->{'remote_group_id'};

        unless (defined $id) {
            my $name = $self->getName();
            my ($date_created, $date_modified);
            $db->writeQuery('INSERT INTO '.$db_name.'.RemoteGroup (remote_group_id, remote_group_source_id, remote_key, name, date_created, date_modified) VALUES (NULL,?,?,?, NOW(),NOW())', $remote_source_id, $remote_key, $name,);

            $id = $db->getLastInsertID();
            $db->readQuery('SELECT date_created, date_modified FROM '.$db_name.'.RemoteGroup WHERE remote_group_id=?', $id);
            
            my $data_ref = $db->fetchRow();
            $self->_setCreationDate(Solstice::DateTime->new($data_ref->{'date_created'}));
            $self->_setModificationDate(Solstice::DateTime->new($data_ref->{'date_modified'}));
        }
        $self->_setID($id);
    }

    my $person_insert = join ',', map { "(NULL, $id, $_)" } keys %{$self->{'_member_people'}};
    
    $db->writeQuery('DELETE FROM '.$db_name.'.PeopleInRemoteGroup WHERE remote_group_id = ?',$id);
    if ($person_insert) {
        $db->writeQuery('INSERT INTO '.$db_name.'.PeopleInRemoteGroup VALUES '.$person_insert);
    }

    $self->{'_tainted_members'} = FALSE;
    return SUCCESS;
}

=item getOwners()
=cut

sub getOwners {
    my $self = shift;
    cluck "getOwners(): Not implemented";
    return Solstice::List->new();
}

=item addOwner($person)
=cut

sub addOwner {
    my $self = shift;
    cluck "addOwner(): Not implemented";
    return FAIL;
}

=item removeOwner($person)
=cut

sub removeOwner {
    my $self = shift;
    cluck "removeOwner(): Not implemented";
    return FAIL;
}

=item isOwner($person)
=cut

sub isOwner {
    my $self = shift;
    #there are currently no owners to remote groups
    return FAIL;
}

=item addMember($person)
=cut

sub addMember {
    my $self = shift;
    cluck "addMember(): Not implemented";
    return FAIL;
}

=item addMembers($list)
=cut

sub addMembers {
    my $self = shift;
    cluck "addMembers(): Not implemented";
    return FAIL;
}

=item removeMember($person)
=cut

sub removeMember {
    my $self = shift;
    cluck "removeMember(): Not implemented";
    return FAIL;
}

=item removeMembers($list)
=cut

sub removeMembers {
    my $self = shift;
    cluck "removeMember(): Not implemented";
    return FAIL;
}

=item removeAllMembers($list)
=cut

sub removeAllMembers {
    my $self = shift;
    cluck "removeAllMembers(): Not implemented";
    return FAIL;
}

=item isMemberGroup($group)
=cut

sub isMemberGroup {
    return FALSE;
}

=item getMemberGroups()
=cut

sub getMemberGroups {
    my $self = shift;
    cluck "getMemberGroups(): Not implemented";
    return Solstice::List->new();
}

=item addMemberGroup($group)
=cut

sub addMemberGroup {
    my $self = shift;
    cluck "addMemberGroup(): Not implemented";
    return FAIL;
}

=item removeMemberGroup($group)
=cut

sub removeMemberGroup {
    my $self = shift;
    cluck "removeMemberGroup(): Not implemented";
    return FAIL;
}

=item isRemoteMemberGroup($group)
=cut

sub isRemoteMemberGroup {
    my $self = shift;
    cluck "isRemoteMemberGroup(): Not implemented";
    return FALSE;
}

=item getRemoteGroups()
=cut

sub getRemoteGroups {
    my $self = shift;
    cluck "getRemoteGroups(): Not implemented";
    return Solstice::List->new();
}

=item addRemoteGroup($group)
=cut

sub addRemoteGroup {
    my $self = shift;
    cluck "addRemoteGroup(): Not implemented";
    return FAIL;
}

=item removeRemoteGroup($group)
=cut

sub removeRemoteGroup {
    my $self = shift;
    cluck "addRemoteGroup(): Not implemented";
    return FAIL;
}

=item getSubgroups()
=cut

sub getSubgroups {
    my $self = shift;
    cluck "getSubgroups(): Not implemented";
    return FAIL;
}

=item addSubgroup($subgroup)

=cut

sub addSubgroup {
    my $self = shift;
    cluck "addSubgroup(): Not implemented";
    return FAIL;
}

=item removeSubgroup($subgroup)
=cut

sub removeSubgroup {
    my $self = shift;
    cluck "removeSubgroup(): Not implemented";
    return FAIL;
}

=item getSubgroupCount()
=cut

sub getSubgroupCount {
    my $self = shift;
    cluck "getSubgroupCount(): Not implemented";
    return 0;
}

=back

=head2 Private Methods

=over 4

=cut

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

    $db->readQuery('SELECT remote_group_id, remote_group_source_id, remote_key, name, date_created, date_modified, date_reconciled
                    FROM '.$db_name.'.RemoteGroup WHERE remote_group_id = ?', $input);
    
    my $data_ref = $db->fetchRow();

    return FALSE unless defined $data_ref->{'remote_group_id'};
    
    $self->{'_initialized_members'} = FALSE;
    
    $self->_setID($data_ref->{'remote_group_id'});
    $self->_setRemoteSourceID($data_ref->{'remote_group_source_id'});
    $self->_setRemoteKey($data_ref->{'remote_key'});
    $self->setName($data_ref->{'name'});
    $self->_setModificationDate(Solstice::DateTime->new($data_ref->{'date_modified'}));
    $self->_setCreationDate(Solstice::DateTime->new($data_ref->{'date_created'}));
    $self->_setReconciliationDate(Solstice::DateTime->new($data_ref->{'date_reconciled'}));
    
    return TRUE;
}

=item _initFromHash($hash_ref)

Does a minimal initialization, with data from an outside source.

=cut

sub _initFromHash {
    my $self = shift;
    my $input = shift;

    $self->{'_initialized_members'} = FALSE;
    
    $self->_setID($input->{'id'});
    $self->_setRemoteSourceID($input->{'remote_source_id'});
    $self->_setRemoteKey($input->{'remote_key'});
    $self->setName($input->{'name'});
    $self->_setModificationDate($input->{'modification_date'});
    $self->_setCreationDate($input->{'creation_date'});
    $self->_setReconciliationDate($input->{'reconciliation_date'});
    
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

    $db->readQuery('SELECT person_id from '.$db_name.'.PeopleInRemoteGroup where remote_group_id =?', $self->getID());
    
    my @member_ids;
    while(my $data_ref = $db->fetchRow()){
        push @member_ids, $data_ref->{'person_id'};
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
    my $self = shift;
    $self->{'_member_groups'} = {};
    return TRUE;
}

=item _initializeRemoteGroups()
=cut

sub _initializeRemoteGroups {
    my $self = shift;
    $self->{'_remote_groups'} = {};
    return TRUE;
}

=item _initializeSubgroups()

=cut

sub _initializeSubgroups {
    return TRUE;
}

=item _getAllMembers($seen_group_hash)

=cut

sub _getAllMembers {
    my $self = shift;
    my $seen_groups = shift;
    $seen_groups = {} unless defined $seen_groups;

    my $remote_key = $self->getRemoteKey();
    return {} unless defined $remote_key;

    $seen_groups->{$remote_key} = 1;

    $self->_initializeMembers() unless $self->{'_initialized_members'};

    return {} unless $self->{'_member_people'};

    my @group_member_hashes;
    push @group_member_hashes, $self->{'_member_people'};
    return { map {%$_} @group_member_hashes};
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

    $db->readQuery('SELECT DISTINCT person_id from '.$db_name.'.PeopleInRemoteGroup where remote_group_id=?',$self->getID());
    
    while(my $data_ref= $db->fetchRow()){
        $member_hash->{$data_ref->{'person_id'}} = TRUE;
    }

    return $member_hash;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Name',
            key  => '_name',
            type => 'String',
        },
        {
            name => 'RemoteSourceID',
            key  => '_remote_source_id',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'RemoteKey',
            key  => '_remote_key',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'Description',
            key  => '_description',
            type => 'String',
        },
        {
            name => 'ReconciliationDate',
            key  => '_reconciliation_date',
            type => 'DateTime',
        },
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

package Solstice::Group;

# $Id: Group.pm 2253 2005-05-18 22:06:27Z mcrawfor $

=head1 NAME

Solstice::Group - Manages sets of people

=head1 SYNOPSIS

  my $group = Solstice::Group->new();
  $group = Solstice::Group->new($group_id);

  $group->setCreator($person);
  my $person = $group->getCreator();
    
  $group->setName('Group name');
  my $name = $group->getName();

  $group->setDescription('Group description');
  my $desc = $group->getDescription();

  my $date = $group->getCreationDate();
  my $date = $group->getModificationDate();
  
  $group->setCreationApplication($application);
  my $application = $group->getCreationApplication();

  my $list = $group->getOwners();
  $group->addOwner($person);
  $group->removeOwner($person);

  my $bool = $group->isMember($person);
  my $list = $group->getMembers();
  my $list = $group->getAllMembers();
  $group->addMember($person);
  $group->addMembers($list);
  $group->removeMember($person);
  $group->removeMembers($list);
  $group->removeAllMembers();
  
  my $bool = $group->isMemberGroup($group2);
  my $list = $group->getMemberGroups();
  $group->addMemberGroup($group2);
  $group->removeMemberGroup($group2);

  my $bool = $group->isRemoteMemberGroup($group2);
  my $list = $group->getRemoteGroups();
  $group->addRemoteGroup($group2);
  $group->removeRemoteGroup($group2);
  $group->removeAllRemoteGroups();
  
  my $list = $group->getSubgroups();
  $group->addSubgroup($subgroup);
  $group->removeSubgroup($subgroup);
  
  my $member_count = $group->getMemberCount();
  $group->store();



=head1 DESCRIPTION

This object tracks groups of people.  Natively it manages sets of people stored in a local data store.  It also can track groups of groups of people, and divide groups of people into subgroups.  It can also track lists of groups stored in remote data stores, if they are presented via a remote group.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::List;
use Solstice::Factory::Person;
use Solstice::Database;
use Solstice::DateTime;
use Solstice::Application;
use Solstice::ImplementationManager;
use Solstice::Service;
use Solstice::Subgroup;

# Using require instead of use prevents subroutine redefined warnings.
require Solstice::Factory::Group;
require Solstice::Factory::Group::Remote;

our ($VERSION) = ('$Revision: 2253 $' =~ /^\$Revision:\s*([\d.]*)/);

use constant TRUE  => 1;
use constant FALSE => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new([$group_id])

Instantiates a new group object.  If given an id of a group, this will return undef unless there is a group in the local data store matching that id.

=cut

sub new {
    my $obj = shift;
    my $input = shift;
    
    my $self = $obj->SUPER::new();
    
    if (defined $input and $input) {
        if ($self->isValidHashRef($input)) {
            $self->_initFromHash($input);
        }
        else {
            return undef unless $self->_initMin($input);
        }
    }else {
        $self->_initEmpty();
    }
        
    return $self;
}

=item clone()

Returns a copy of this group, including group members, subgroups, and linked 
remote groups.

=cut

sub clone {
    my $self = shift;

    my $clone = Solstice::Group->new();
    $clone->setName($self->getName());
    $clone->setDescription($self->getDescription());
    $clone->setCreator($self->getCreator());
    $clone->setCreationApplication($self->getCreationApplication());
    $clone->addMembers($self->getMembers());
    $clone->addOwners($self->getOwners());

    for my $subgroup (@{$self->getSubgroups()->getAll()}) {
        $clone->addSubgroup($subgroup->clone());
    }

    for my $remote_group (@{$self->getRemoteGroups()->getAll()}) {
        $clone->addRemoteGroup($remote_group);
    }
    
    $clone->_taint();
    
    return $clone;
}    

=item delete()

Delete the group.

=cut

sub delete {
    my $self = shift;

    return FALSE unless defined $self->getID();
    
    # Use Solstice::ImplementationManager to inform tools that this group
    # has been deleted
    my $impl_manager = Solstice::ImplementationManager->new();
    my $tool_list = $impl_manager->createList({
        method => 'groupDeleted',
        args   => [$self],
    });

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->writeQuery('UPDATE '.$db_name.'.Groups SET is_visible=0, date_modified=NOW() WHERE group_id=?', $self->getID());

    return TRUE;
}

=item store()

Saves the group to the data store.  Returns TRUE on success, FALSE otherwise. 
Saving will fail if the following attributes are not defined: name, creator, 
and creating application.

=cut

sub store {
    my $self = shift;
    
    # This process needs to store the group information,
    # Person Membership,
    # Group Membership,
    # Remote group Membership, and 
    # Subgroups and their membership,
    
    $self->_initializeOwners() unless $self->{'_initialized_owners'};
    $self->_initializeMembers() unless $self->{'_initialized_members'};
    $self->_initializeMemberGroups() unless $self->{'_initialized_member_groups'};
    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};
    $self->_initializeSubgroups() unless $self->{'_initialized_subgroups'};
    
    my $db = Solstice::Database->new();
    
    my $id             = $self->getID();
    my $name           = $self->getName();
    if (!defined $self->getName()) {
        die "Group must have a name";
    }
    my $description    = $self->getDescription();
    if (!defined $self->getCreator()) {
        die "No creator set into group before store was called";
    }
    my $creator_id     = $self->getCreator()->getID();
    my $application    = $self->getCreationApplication();
    unless (defined $application) {
        warn "store(): Creation application is not defined";
        return FALSE;
    }

    my $application_id = $application->getID();
    my ($date_created, $date_modified);
    my $db_name = $self->getConfigService()->getDBName();

    if (!defined $self->{'_group_owners'}) {
        die "Groups must have at least 1 owner.";
    }

    my $group_id;
    if (defined $id) {
        $group_id = $id;
        $db->writeQuery('UPDATE '.$db_name.'.Groups SET name=?, description=?,date_modified=NOW(), application_id=?, creator_id=? WHERE group_id = ?', $name, $description, $application_id, $creator_id, $group_id);

        $db->readQuery('SELECT date_modified FROM '.$db_name.'.Groups where group_id = ?',$group_id);
        
        $date_modified = $db->fetchRow()->{'date_modified'};
        $self->_setModificationDate(Solstice::DateTime->new($date_modified));
    
    } else {
        $db->writeQuery('INSERT INTO '.$db_name.'.Groups (name, description, date_modified, date_created, creator_id, application_id) VALUES (?, ?, NOW(), NOW(), ?, ?)',$name,$description,$creator_id,$application_id);

        my $new_id = $db->getLastInsertID();
        $db->readQuery('SELECT group_id, date_created, date_modified from '.$db_name.'.Groups WHERE group_id=?',$new_id);
        my $data_ref = $db->fetchRow();
        $self->_setID($data_ref->{'group_id'});
        $self->_setCreationDate(Solstice::DateTime->new($data_ref->{'date_created'}));
        $self->_setModificationDate(Solstice::DateTime->new($data_ref->{'date_modified'}));
        $group_id = $data_ref->{'group_id'};
    }

    my @value_array;
    my @insert_array;
    for my $key ( keys( %{$self->{'_group_owners'}}) ){
        push @value_array, (undef, $group_id, $key);
        push @insert_array, '(?, ?, ?)';
    }
    my $insert_string = join ',', @insert_array;

    $db->writeQuery('DELETE FROM '.$db_name.'.GroupOwner WHERE group_id = ?', $group_id);
    $db->writeQuery('INSERT INTO '.$db_name.'.GroupOwner VALUES '. $insert_string, @value_array);

    @value_array = ();
    @insert_array= ();

    
    # We should probably come up with a better way of doing this... deleting everyone and readding is a bit crude.
    # XXX - make this smarter
    for my $key (keys %{$self->{'_member_people'}}){
        push @value_array, (undef, $group_id, $key);
        push @insert_array, '(?, ?, ?)';
    }
    $insert_string = join ',', @insert_array;

    $db->writeQuery('DELETE FROM '.$db_name.'.PeopleInGroup WHERE group_id = ?', $group_id);
    if (@value_array) {
        $db->writeQuery('INSERT INTO '.$db_name.'.PeopleInGroup VALUES '. $insert_string, @value_array);
    }

    @value_array = ();
    @insert_array= ();

    
    # XXX - make this smarter as well...
    for my $key (keys( %{$self->{'_member_groups'}})){
        push @value_array, (undef $group_id, $key);
        push @insert_array, '(?, ?, ?)';
    }
    $insert_string = join ',', @insert_array;
    
    $db->writeQuery('DELETE FROM '.$db_name.'.GroupsInGroup WHERE parent_group_id = ?', $group_id);
    if (@value_array) {
        $db->writeQuery('INSERT INTO '.$db_name.'.GroupsInGroup VALUES'. $insert_string, @value_array);
    }

    @value_array = ();
    @insert_array= ();


    # XXX - this as well...  
    for my $remote_group_id (keys %{$self->{'_remote_groups'}}) {
        my $remote_group = $self->{'_remote_groups'}->{$remote_group_id};
        my $group_ref = ref ($remote_group);
        $self->loadModule($group_ref);
        $remote_group->store();
        push @value_array, (undef, $group_id, $remote_group_id);
        push @insert_array, '(?, ?, ?)';
    }
    $insert_string = join ',', @insert_array;
    
    $db->writeQuery('DELETE FROM '.$db_name.'.RemoteGroupsInGroup WHERE parent_group_id = ?', $group_id);
    if ($insert_string) {
        $db->writeQuery('INSERT INTO '.$db_name.'.RemoteGroupsInGroup VALUES '. $insert_string, @value_array);
    }

    @value_array = ();
    @insert_array= ();


    my $member_hash = {};
    $self->_populateMemberHash($member_hash);
    
    # This is the one bit of member data that is under the domain of this i
    # group to modify... so we start by saving all of the subgroups.  
    # Since subgroups are aware of the group they are a subset of, all we need 
    # to do in the group is remove from the data store any subgroups that 
    # have been removed from the object.
    for my $subgroup_id (keys %{$self->{'_subgroups'}}) {
        my $subgroup = $self->{'_subgroups'}->{$subgroup_id};
        
        # Remove subgroup members that no longer exist
        for my $person (@{$subgroup->getMembers()->getAll()}) {
            $subgroup->removeMember($person) unless exists $member_hash->{$person->getID()};
        }
        
        $subgroup->store();
        # If a subgroup has a new id as a result of being stored 
        # (which happens for new subgroups)
        # remove the old subgroup entry and add the new.
        my $new_subgroup_id = $subgroup->getID();
        if ($new_subgroup_id ne $subgroup_id) {
            delete $self->{'_subgroups'}->{$subgroup_id};
            $self->{'_subgroups'}->{$new_subgroup_id} = $subgroup;
        }
        push @value_array, (undef, $group_id, $new_subgroup_id);
        push @insert_array, '(?, ?, ?)';
    }
    $insert_string = join(",", @insert_array);

    $db->writeQuery('DELETE FROM '.$db_name.'.SubgroupsInGroup WHERE parent_group_id = ?',$group_id);
    if (@value_array) {
        $db->writeQuery('INSERT INTO '.$db_name.'.SubgroupsInGroup VALUES '. $insert_string, @value_array);
    }
    
    for my $subgroup (values %{$self->{'_removed_subgroups'}}) {
        next unless defined $subgroup;
        $subgroup->delete();
    }
    $self->{'_removed_subgroups'} = undef;
        
    # Use Solstice::ImplementationManager to inform tools that this group 
    # has been modified
    my $impl_manager = Solstice::ImplementationManager->new();
    my $tool_list = $impl_manager->createList({
        method => 'groupModified',
        args   => [$self],
    });

    return TRUE;
}

=item getOwners()

This will return a Solstice::List, containing Solstice::Person::<X> objects.  All people in the list are considered full owners of this object.  If there are no owners of the group, this will return a list with no elements.

=cut

sub getOwners {
    my $self = shift;

    $self->_initializeOwners() unless $self->{'_initialized_owners'};
    
    my $list = Solstice::List->new();
    foreach my $person (values %{$self->{'_group_owners'}}) {
        $list->add($person);
    }
    
    return $list;
}

=item addOwners($list)

Add person objs to the Group. This method requires a Solstice::List.

=cut

sub addOwners {
    my $self = shift;
    my $list = shift;

    unless ($self->isValidList($list)) {
        warn 'addOwners(): requires a Solstice::List';
        return FALSE;
    }

    my $iterator = $list->iterator();
    while (my $owner = $iterator->next()) {
        $self->addOwner($owner);
    }
    
    return TRUE;
}

=item addOwner($person)

Adds the given person as an owner to the group.  If the person is already an owner, this won't fail, but it will also not add them a second time.  If the person that is passed in is not a stored person, in a subclass of Solstice::Person, this will fail.

=cut

sub addOwner {
    my $self = shift;
    my $person = shift;

    return FALSE unless defined $person;
    return FALSE unless $self->isValidPerson($person);
    
    my $person_id = $person->getID();
    return FALSE unless defined $person_id;

    $self->_initializeOwners() unless $self->{'_initialized_owners'};
    $self->{'_group_owners'}->{$person_id} = $person;
    
    return TRUE;
}

=item removeOwner($person)

Removes the given person from the set of owners.  The person object that is given must be a subclass of Solstice::Solstice, and must have been stored.

=cut

sub removeOwner {
    my $self = shift;
    my $person = shift;

    return FALSE unless $self->isValidPerson($person);

    my $person_id = $person->getID();
    return FALSE unless defined $person_id;

    $self->_initializeOwners() unless $self->{'_initialized_owners'};
    delete $self->{'_group_owners'}->{$person_id};

    return TRUE;
}

=item getMembers()

Returns a Solstice::List, containing Solstice::Person objects. This list consists of all members of the groups, excluding member groups, or people who are in remote groups.

=cut

sub getMembers {
    my $self = shift;

    $self->_initializeMembers() unless $self->{'_initialized_members'};

    my $list = Solstice::List->new();
    for my $person (values %{$self->{'_member_people'}}) {
        $list->add($person);
    }
    return $list;
}

=item getAllMembers()

Returns a Solstice::List, containing all members of the groups, including members of member groups, and members of remote groups.

=cut

sub getAllMembers {
    my $self = shift;

    my $list = Solstice::List->new();
    for my $person (values %{$self->_getAllMembers()}) {
        $list->add($person);
    }
    return $list;
}

=item getMemberCount()

Returns the number of members for the group.

=cut

sub getMemberCount {
    my $self = shift;
    
    my $member_hash = {};

    $self->_populateMemberHash($member_hash);
    
    return scalar keys %$member_hash;
}

=item isMember($person)

Returns TRUE if the given person is a member of this group, recursively,
FALSE otherwise.  

=cut

sub isMember {
    my $self = shift;
    my $person = shift;

    return TRUE if $self->isOwner($person);

    return FALSE unless defined $person;
    return FALSE unless $self->isValidPerson($person);
    my $person_id = $person->getID();
    return FALSE unless defined $person_id;

    my $service = Solstice::Service->new();

    my $member_hash;
    if(! $self->{'_initialized_members'} ){ #only use the cache if we don't have a local copy
        $member_hash = $service->get("solstice_group_members_".$self->getID());
    }

    # Doing the db lookup once per page load should be live enough...
    if (!defined $member_hash) {
        $member_hash = {};
        $self->_populateMemberHash($member_hash);
        if(! $self->{'_initialized_members'} ){ #only use the cache if we don't have a local copy
            $service->set("solstice_group_members_".$self->getID(), $member_hash);
        }
    }

    return exists $member_hash->{$person_id};
}

sub isOwner {
    my $self = shift;
    my $person = shift;

    return FALSE unless defined $person;
    return FALSE unless $self->isValidPerson($person);

    my $owners = $self->getOwners();
    my $iterator = $owners->iterator();
    while(my $owner = $iterator->next()){
        return TRUE if $owner->equals($person);
    }
    return FALSE;
}

=item isLocalMember($person)

Returns TRUE if the given person is a member of this group, non-recursively, FALSE otherwise.

=cut

sub isLocalMember {
    my $self = shift;
    my $person = shift;

    return FALSE unless defined $person;

    return FALSE unless $self->isValidPerson($person);
    my $person_id = $person->getID();
    return FALSE unless defined $person_id;

    $self->_initializeMembers() unless $self->{'_initialized_members'};

    return defined $self->{'_member_people'}->{$person_id} ? TRUE : FALSE;
}

=item addMember($person)

Adds the given person object to the group.  A person can only be added to a group once, though multiple adds will not result in an error being raised.

=cut

sub addMember {
    my $self = shift;
    my $person = shift;

    return FALSE unless defined $person;
    
    return FALSE unless $self->isValidPerson($person);
    my $person_id = $person->getID();
    return FALSE unless defined $person_id;

    $self->_initializeMembers() unless $self->{'_initialized_members'};

    $self->{'_member_people'}->{$person_id} = $person;
    
    return TRUE;
}

=item addMembers($list)

Add person objs to the Group. This method requires a Solstice::List.

=cut

sub addMembers {
    my $self = shift;
    my $list = shift;

    unless ($self->isValidList($list)) {
        warn 'addMembers(): requires a Solstice::List';
        return FALSE;
    }
    
    my $iterator = $list->iterator();
    while ($iterator->hasNext()) {
        return FALSE unless $self->addMember($iterator->next());
    }
    return TRUE;
}

=item removeMember($person)

Removes the given person from the group.  This only removes the user from the group itself, it does not traverse into member groups, or modify any entries for a remote group.

=cut

sub removeMember {
    my $self = shift;
    my $person = shift;

    return FALSE unless $self->isValidPerson($person);

    my $person_id = $person->getID();
    return FALSE unless defined $person_id;

    $self->_initializeMembers() unless $self->{'_initialized_members'};
    delete $self->{'_member_people'}->{$person_id};

    return TRUE;
}

=item removeMembers($list)

Remove person objs from the Group. This method requires a Solstice::List.

=cut

sub removeMembers {
    my $self = shift;
    my $list = shift;
    
    unless ($self->isValidList($list)) {
        warn 'removeMembers(): requires a Solstice::List';
        return FALSE;
    }

    my $iterator = $list->iterator();
    while ($iterator->hasNext()) {
        return FALSE unless $self->removeMember($iterator->next());
    }
    return TRUE;
}

=item removeAllMembers()

Remove all members of the group, non-recursively.

=cut

sub removeAllMembers {
    my $self = shift;
    
    $self->_initializeMembers() unless $self->{'_initialized_members'};
    
    $self->{'_member_people'} = {};
    
    return TRUE;
}

=item clear()

See removeAllMembers().

=cut

sub clear {
    my $self = shift;
    warn "clear() is deprecated, use removeAllMembers() instead";
    $self->removeAllMembers();
}

=item isMemberGroup($group)

Returns a bool, TRUE if the group is a member group, FALSE otherwise. Not recursive.

=cut

sub isMemberGroup {
    my $self = shift;
    my $group = shift;
    warn "Member groups are not implemented!";

    return FALSE unless defined $group;
    return FALSE unless $self->isValidGroup($group);

    my $group_id = $group->getID();
    return FALSE unless defined $group_id;

    $self->_initializeMemberGroups() unless $self->{'_initialized_membergroups'};
    return defined $self->{'_member_groups'}->{$group_id};
}

=item getMemberGroups()

Returns a Solstice::List, containing all groups that are members of the group.  This only includes local groups, no remote groups will be in this list.

=cut

sub getMemberGroups {
    my $self = shift;
    warn "Member groups are not implemented!";
    $self->_initializeMemberGroups() unless $self->{'_initialized_membergroups'};

    my $list = Solstice::List->new();
    foreach my $group (values %{$self->{'_member_groups'}}) {
        $list->add($group);
    }
    return $list;
}

=item addMemberGroup($group)

This will add the given group to the current group.  This will return TRUE on success, FALSE on failure.  This can fail in the case that the given group is not a Solstice::Group, or if the group has not been saved.  Group membership can be cyclical.

=cut

sub addMemberGroup {
    my $self = shift;
    my $group = shift;

    warn "Member groups are not implemented!";

    return FALSE unless defined $group;
    return FALSE unless $self->isValidGroup($group);

    my $group_id = $group->getID();
    return FALSE unless defined $group_id;

    $self->_initializeMemberGroups() unless $self->{'_initialized_membergroups'};
    $self->{'_member_groups'}->{$group_id} = $group;

    return TRUE;
}

=item removeMemberGroup($group)

This will remove the given group from the set of member groups.  This will only remove the member group from the group it is called on, it does not recurse into member groups.

=cut

sub removeMemberGroup {
    my $self = shift;
    my $group = shift;
    warn "Member groups are not implemented!";

    return FALSE unless defined $group;
    return FALSE unless $self->isValidGroup($group);

    my $group_id = $group->getID();
    return FALSE unless defined $group_id;

    $self->_initializeMemberGroups() unless $self->{'_initialized_membergroups'};
    delete $self->{'_member_groups'}->{$group_id};

    return TRUE;
}

=item isRemoteMemberGroup($group)

Returns a bool, TRUE if the group is a remote member group, FALSE otherwise.

=cut

sub isRemoteMemberGroup {
    my $self = shift;
    my $group = shift;

    return FALSE unless $self->_isValidRemoteGroup($group);

    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};
    return defined $self->{'_remote_groups'}->{$group->getID()};
}

=item getRemoteGroups()

Returns a Solstice::List, containing instances of any and all remote groups that are members of the given group.

=cut

sub getRemoteGroups {
    my $self = shift;
    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};

    my $list = Solstice::List->new();
    foreach my $group (values %{$self->{'_remote_groups'}}) {
        $self->loadModule(ref $group);
        $list->add($group);
    }
    return $list;
}

=item addRemoteGroup($group)

This will add the given group to the current group.  This will return TRUE on success, FALSE on failure.  This can fail in the case that the given group is not a Solstice::Group::Remote, or if the group has not been saved.  

=cut

sub addRemoteGroup {
    my $self = shift;
    my $group = shift;

    return FALSE unless $self->_isValidRemoteGroup($group); 

    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};
    $self->{'_remote_groups'}->{$group->getID()} = $group;

    return TRUE;
}

=item removeRemoteGroup($group)

This will remove the given group from the set of member groups. This
will only remove the member group from the group it is called on,
it does not recurse into member groups.

=cut

sub removeRemoteGroup {
    my $self = shift;
    my $group = shift;
    
    return FALSE unless $self->_isValidRemoteGroup($group);
    
    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};
    delete $self->{'_remote_groups'}->{$group->getID()};

    return TRUE;
}

=item removeAllRemoteGroups()

Remove all remote groups that are currently attached to the group.

=cut

sub removeAllRemoteGroups {
    my $self = shift;

    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};
    $self->{'_remote_groups'} = {};

    return TRUE;
}

=item getSubgroups()

Returns a Solstice::List, containing all subgroups of the given list.  This does not recurse into member groups.

=cut

sub getSubgroups {
    my $self = shift;
    $self->_initializeSubgroups() unless $self->{'_initialized_subgroups'};

    my $list = Solstice::List->new();
    foreach my $group (values %{$self->{'_subgroups'}}) {
        $list->add($group);
    }
    return $list;
}

=item addSubgroup($subgroup)

Adds the given subgroup to the set of subgroups in the current group.
Subgroup membership can overlap, and can include membership from member
groups and remote groups.  The subgroup must watch the membership of the
group it is attached to, and if a member of the subgroup is no longer
a member of the subgroup, display and use of that member must cease.

The subgroup must be in the data store before being added to the group.

=cut

sub addSubgroup {
    my $self = shift;
    my $subgroup = shift;

    return FALSE unless defined $subgroup;
    return FALSE unless $self->_isValidSubgroup($subgroup);

    my $subgroup_id = $subgroup->getID();

    $self->_initializeSubgroups() unless $self->{'_initialized_subgroups'};

    if (defined $subgroup_id) {
        $self->{'_subgroups'}->{$subgroup_id} = $subgroup;
    }

    return TRUE;

}

=item removeSubgroup($subgroup)

Removes the given subgroup from the set of subgroups.

=cut

sub removeSubgroup {
    my $self = shift;
    my $subgroup = shift;

    return FALSE unless defined $subgroup;
    return FALSE unless $self->_isValidSubgroup($subgroup);

    my $subgroup_id = $subgroup->getID();
    return FALSE unless defined $subgroup_id;

    $self->_initializeSubgroups() unless $self->{'_initialized_subgroups'};
    $self->{'_removed_subgroups'}->{$subgroup_id} = $self->{'_subgroups'}->{$subgroup_id};
    delete $self->{'_subgroups'}->{$subgroup_id};
    
    return TRUE;

}

=item getSubgroupCount()

Returns the number of subgroups for the group.

=cut

sub getSubgroupCount {
    my $self = shift;
    
    $self->_initializeSubgroups() unless $self->{'_initialized_subgroups'};
    return scalar (keys %{$self->{'_subgroups'}});
}

=back

=head2 Private Methods

=over 4

=cut

=item _initEmpty()

=cut

sub _initEmpty {
    my $self = shift;

    $self->{'_initialized_owners'} = TRUE;
    $self->{'_initialized_members'} = TRUE;
    $self->{'_initialized_member_groups'} = TRUE;
    $self->{'_initialized_remote_groups'} = TRUE;
    $self->{'_initialized_subgroups'} = TRUE;
}

=item _initMin($group_id)

Initializes the minimum amount of data about the group as it can. Loads no 
member groups, subgroups, people, or class lists.

=cut

sub _initMin {
    my $self = shift;
    my $input = shift;

    return FALSE unless $self->_isValidInteger($input);
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();
    
    $db->readQuery('SELECT group_id, name, description, date_created, date_modified, application_id, creator_id 
                    FROM '.$db_name.'.Groups WHERE is_visible=1 AND group_id = ?',$input);
    my $data_ref = $db->fetchRow();
    my $group_id = $data_ref->{'group_id'};

    return FALSE unless defined $group_id;
    
    $self->{'_initialized_owners'} = FALSE;
    $self->{'_initialized_subgroups'} = FALSE;
    $self->{'_initialized_membergroups'} = FALSE;
    $self->{'_initialized_members'} = FALSE;
    $self->{'_initialized_remote_groups'} = FALSE;
    
    my $person_factory = Solstice::Factory::Person->new();

    $self->_setID($group_id);
    $self->setName($data_ref->{'name'});
    $self->setDescription($data_ref->{'description'});
    $self->_setModificationDate(Solstice::DateTime->new($data_ref->{'date_modified'}));
    $self->_setCreationDate(Solstice::DateTime->new($data_ref->{'date_created'}));
    $self->setCreationApplication(Solstice::Application->new($data_ref->{'application_id'}));
    $self->setCreator($person_factory->createByID($data_ref->{'creator_id'}));
    
    return TRUE;
}

=item _initFromHash($hash_ref)

Does a minimal initialization, with data from an outside source.

=cut

sub _initFromHash {
    my $self = shift;
    my $input = shift;

    $self->{'_initialized_owners'} = FALSE;
    $self->{'_initialized_subgroups'} = FALSE;
    $self->{'_initialized_membergroups'} = FALSE;
    $self->{'_initialized_members'} = FALSE;
    $self->{'_initialized_remote_groups'} = FALSE;
    
    $self->_setID($input->{'id'});
    $self->setName($input->{'name'});
    $self->setDescription($input->{'description'});
    $self->_setModificationDate($input->{'modification_date'});
    $self->_setCreationDate($input->{'creation_date'});
    $self->setCreationApplication($input->{'creation_application'});
    $self->setCreator($input->{'creator'});

    if (defined $input->{'subgroups'}) {
        $self->{'_subgroups'} = $input->{'subgroups'};
        $self->{'_initialized_subgroups'} = TRUE;
    }

    if (defined $input->{'remote_groups'}) {
        $self->{'_remote_groups'} = $input->{'remote_groups'};
        $self->{'_initialized_remote_groups'} = TRUE;
    }
    
    if (defined $input->{'member_group_ids'}) {
        $self->{'_member_group_ids'} = $input->{'member_group_ids'};
    }
    
    if (defined $input->{'owners'}) {
        $self->{'_group_owners'} = $input->{'owners'};
        $self->{'_initialized_owners'} = TRUE;
    }
   
    return TRUE;
}

=item _initializeOwners()

Goes to the data store to retrieve the list of owners of this group.

=cut

sub _initializeOwners {
    my $self = shift;
    $self->{'_initialized_owners'} = TRUE;
    
    return TRUE unless defined $self->getID();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT person_id FROM '.$db_name.'.GroupOwner where group_id = ?',$self->getID());
    
    my @owner_ids;
    while( my $row = $db->fetchRow()) {
        push @owner_ids, $row->{'person_id'};
    }

    my $person_factory = Solstice::Factory::Person->new();
    my $people = $person_factory->createByIDs(\@owner_ids)->getAll();
    
    $self->{'_group_owners'} = {};
    for my $person (@$people) {
        $self->{'_group_owners'}->{$person->getID()} = $person;
    }
    
    return TRUE;
}

=item _initializeMembers()

Goes to the data store to retrive the list of members for this group.

=cut

sub _initializeMembers {
    my $self = shift;
    
    return FALSE unless defined $self->getID();

    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT person_id FROM '.$db_name.'.PeopleInGroup WHERE group_id = ?',$self->getID());
    
    my @member_ids;
    while( my $row =$db->fetchRow()) {
        push @member_ids, $row->{'person_id'};
    }

    my $person_factory = Solstice::Factory::Person->new();
    my $people = $person_factory->createByIDs(\@member_ids)->getAll();
    
    $self->{'_member_people'} = {};
    for my $person (@$people) {
        $self->{'_member_people'}->{$person->getID()} = $person;
    }
    
    return $self->{'_initialized_members'} = TRUE;
}

=item _initializeMemberGroups()

Goes to the data store to retrieve the list of member groups for this group.

=cut

# TODO - decide whether this should not recurse into a group loop, if a loop exists.

sub _initializeMemberGroups {
    my $self = shift;
    
    return FALSE unless defined $self->getID();
   
    $self->{'_initialized_membergroups'} = TRUE;
   
    my $member_ids = [];
    if (defined $self->{'_member_group_ids'}) {
        $member_ids = $self->{'_member_group_ids'};
    } else {
        my $db = Solstice::Database->new();
        my $db_name = $self->getConfigService()->getDBName();

        $db->readQuery('SELECT group_id FROM '.$db_name.'.GroupsInGroup WHERE parent_group_id = ?', $self->getID());
    
        while(my $row = $db->fetchRow()) {
            push @$member_ids, $row->{'group_id'};
        }
    }
    return TRUE unless scalar @$member_ids;
    
    my $factory = Solstice::Factory::Group->new();
    my $groups = $factory->createByIDs($member_ids)->getAll();
    
    $self->{'_member_groups'} = {};
    for my $group (@$groups) {
        $self->{'_member_groups'}->{$group->getID()} = $group;
    }
    
    return TRUE;
}

=item _initializeRemoteGroups()

Goes to the data store to retrieve the list of remote groups for this group.

=cut

sub _initializeRemoteGroups {
    my $self = shift;

    return FALSE unless defined $self->getID();
    
    my $factory = Solstice::Factory::Group::Remote->new();
    my $groups = $factory->createByGroupID($self->getID())->getAll();
    
    for my $group (@$groups) {
        $self->{'_remote_groups'}->{$group->getID()} = $group;
    }
    
    return $self->{'_initialized_remote_groups'} = TRUE;
}

=item _initializeSubgroups()

Goes to the data store to retrieve the list of subgroups for this group.

=cut

sub _initializeSubgroups {
    my $self = shift;

    return FALSE unless defined $self->getID();
    
    my $db = Solstice::Database->new();
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT subgroup_id FROM '.$db_name.'.SubgroupsInGroup where parent_group_id = ?', $self->getID());
   
    $self->{'_subgroups'} = {};
    while ( my $row = $db->fetchRow() ) {
        my $subgroup = Solstice::Subgroup->new($row->{'subgroup_id'});
        $self->{'_subgroups'}->{$subgroup->getID()} = $subgroup;
    }

    return $self->{'_initialized_subgroups'} = TRUE;
}

=item _isValidSubgroup($group)

=cut

sub _isValidSubgroup {
    my $self  = shift;
    my $group = shift;
    return (defined $group and UNIVERSAL::isa($group, 'Solstice::Subgroup'));
}

=item _isValidRemoteGroup($group)



=cut

sub _isValidRemoteGroup {
    my $self  = shift;
    my $group = shift;
    return (defined $group and UNIVERSAL::isa($group, 'Solstice::Group::Remote') and $group->getID());
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

    $seen_groups->{$group_id} = 1;
    my $group_members;

    # Make sure we have the 3 sets of data we need to proceed...
    $self->_initializeMembers() unless $self->{'_initialized_members'};
    $self->_initializeMemberGroups() unless $self->{'_initialized_member_groups'};
    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};

    # This is a bit naive, and may not perform very well. This may, however,
    # be the desired behavior for this model, in case member groups have 
    # unstored changes you want to have reflected in your app.

    # This array is used to make it so we're not constantly reallocating memory 
    # for the membership list. By keeping an array ref, we're able to just point 
    # at the memory that has already been allocated.
    my @group_member_hashes = ();
    for my $group (values %{$self->{'_member_groups'}}) {
        my $member_group_id = $group->getID();
        next unless defined $member_group_id;
        next if (defined $seen_groups->{$member_group_id});

        push @group_member_hashes, $group->_getAllMembers($seen_groups);
    }

    for my $remote_group (values %{$self->{'_remote_groups'}}) {
        my $group_ref = ref ($remote_group);
        $self->loadModule($group_ref);

        my $remote_group_id = $remote_group->getID();
        next unless defined $remote_group_id;
        next if (defined $seen_groups->{$remote_group_id});

        push @group_member_hashes, $remote_group->_getAllMembers($seen_groups);
    }
    push @group_member_hashes, $self->{'_member_people'};

    return { map {%$_} @group_member_hashes};
}
    
=item _populateMemberHash(\%member_hash)

Recursive function that builds a hash of group members

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

    $self->_initializeMemberGroups() unless $self->{'_initialized_member_groups'};
    for my $member_group (values %{$self->{'_member_groups'}}) {
        $member_group->_populateMemberHash($member_hash);
    }

    $self->_initializeRemoteGroups() unless $self->{'_initialized_remote_groups'};
    for my $remote_group (values %{$self->{'_remote_groups'}}) {
        my $package = ref $remote_group;
        eval {$self->loadModule($package)};
        unless ($@) {
            $remote_group->_populateMemberHash($member_hash);
        }
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
    my $db_name = $self->getConfigService()->getDBName();

    $db->readQuery('SELECT DISTINCT person_id from '.$db_name.'.PeopleInGroup WHERE group_id = ?',$self->getID());

    while (my $row =$db->fetchRow()) { $member_hash->{$row->{'person_id'}} = TRUE; }
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
            name => 'Description',
            key  => '_description',
            type => 'String',
        },
        {
            name => 'Creator',
            key  => '_creator',
            type => 'Person',
        },
        {
            name => 'CreationApplication',
            key  => '_creation_application',
            type => 'Solstice::Application',
        },
        {
            name => 'CreationDate',
            key  => '_creation_date',
            type => 'DateTime',
            private_set => TRUE,
        },
        {
            name => 'ModificationDate',
            key  => '_modification_date',
            type => 'DateTime',
            private_set => TRUE,
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

package Solstice::AuthZManager;

# $Id: AuthZManager.pm 3395 2006-05-18 22:22:03Z jlaney $

=head1 NAME

Solstice::AuthZManager - For modifying the roles available within the Solstice framework.

=head1 SYNOPSIS

  use Solstice::AuthZManager;

  my $authz_manager = Solstice::AuthZManager->new($auth_id);
  $authz_manager->addRole($group, $role);
  $authz_manager->removeRole($group, $role);
  $authz_manager->removeGroup($group);
  my $groups = $authz_manager->getGroups();
  my $bool = $authz_manager->groupHasRole($group, $role);
  $authz_manager->store();

=head1 DESCRIPTION

An interface for managing the connections betweens groups and roles.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::Database;
use Solstice::AuthZ::Role;
use Solstice::Group;

our ($VERSION) = ('$Revision: 3395 $' =~ /^\$Revision:\s*([\d.]*)/);

use constant TRUE     => 1;
use constant FALSE    => 0;

=head2 Superclass

L<Model|Model>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructor.

=cut

sub new {
    my $obj = shift;
    my $input = shift;
    
    my $self = $obj->SUPER::new(@_);
    
    if($self->isValidHashRef($input)){
        $self->_initFromHashRef($input);
    }elsif($input){
        $self->_init($input);
    }
    
    return $self;
}

=item addRole($group, $role)

Connects a group and a role together.

=cut

sub addRole {
    my $self  = shift;
    my $group = shift;
    my $role  = shift;

    if (!defined $group or !defined $role) {
        return FALSE;
    }

    $self->_addGroup($group);
    $self->{'_roles'}{$group->getID()}{$role->getID()} = $role;
    return TRUE;
}

=item removeRole($group, $role)

Removes the association between a group and a role.

=cut

sub removeRole {
    my $self  = shift;
    my $group = shift;
    my $role  = shift;
    if (!defined $group or !defined $role) {
        return FALSE;
    }

    $self->{'_roles'}{$group->getID()}{$role->getID()} = undef;
}

=item groupHasRole($group, $role)

Returns true is the group and role are linked.

=cut

sub groupHasRole {
    my $self  = shift;
    my $group = shift;
    my $role  = shift;

    if (!defined $group or !defined $role) {
        return FALSE;
    }
    my $test_role = $self->{'_roles'}{$group->getID()}{$role->getID()};
    if (defined $test_role) {
        return TRUE;
    }
    return FALSE;
}

=item groupsWithRole($role)

Returns an array ref of all groups with the given role.

=cut

sub groupsWithRole {
    my $self = shift;
    my $role = shift;
    if (!defined $role) {
        return []; 
    }

    my $all_groups = $self->getGroups();
    my @groups;
    foreach my $group (@$all_groups) {
        if (defined $self->{'_roles'}{$group->getID()}{$role->getID()}) {
            push @groups, $group;
        }
    }
    return \@groups
}

=item removeGroup($group)

Removes a group, and all of it's links to roles.

=cut

sub removeGroup {
    my $self = shift;
    my $group = shift;

    if (!defined $group) {
        return FALSE;
    }
    
    delete $self->{'_roles'}{$group->getID()};
    delete $self->{'_groups'}{$group->getID()};
}

=item getGroups()

Returns an array ref of all of the groups that have (or potentially have) roles.
To remove a group from this list, you must call removeGroup, 
rather than just removing all Roles from the group.

=cut

sub getGroups {
    my $self = shift;
    my @groups = values %{$self->{'_groups'}};
    return \@groups;
}

=item hasGroup($group)

Returns TRUE if $group exists, FALSE otherwise

=cut

sub hasGroup {
    my $self = shift;
    my $group = shift;
    return FALSE unless (defined $group and $group->getID());
    return exists $self->{'_groups'}{$group->getID()};
}

sub clone {
    my $self = shift;

    my $clone = Solstice::AuthZManager->new();

    my $groups = $self->getGroups();
    foreach my $group (@$groups) {
        my $cloned_group = $group->clone();
        #not ideal, but in order to use addRole the group needs an id
        $cloned_group->store();

        my $group_id = $group->getID();
        foreach my $role_id (keys %{$self->{_roles}{$group_id}}) {
            if (defined $self->{_roles}{$group_id}{$role_id}) {
                $clone->addRole($cloned_group, $self->{_roles}{$group_id}{$role_id}); 
            }
        }
    }

    return $clone;
    
}
=item store()

Saves the current role/group relationships.

=cut

sub store {
    my $self = shift;
    
    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my $authz_id = $self->getID();
    my $role_values = '';
    my @role_data;

    if (!defined $authz_id or $authz_id eq "NULL") {
        my $user_service = Solstice::UserService->new();
        my $current_user = $user_service->getUser();

        #This is just to get a unique object auth id, which the caller must store
        $db->writeQuery('INSERT INTO '.$db_name.'.ObjectAuth (person_id) VALUES (?)', $current_user->getID());

        $authz_id = $db->getLastInsertID();
        $self->_setID($authz_id);
    }
    
    my $groups = $self->getGroups();
    foreach my $group (@$groups) {
        my $group_id = $group->getID();
        foreach my $role_id (keys %{$self->{_roles}{$group_id}}) {
            if (defined $self->{_roles}{$group_id}{$role_id}) {
                $role_values .= '(?, ?, ?),';
                push @role_data, $group->getID();
                push @role_data, $role_id;
                push @role_data, $authz_id;
            }
        }
    }
    $db->writeQuery('DELETE FROM '.$db_name.'.RoleImplementations WHERE object_auth_id=?', $authz_id);
    if (defined $role_values and $role_values) {
        chop $role_values;
        $db->writeQuery('INSERT INTO '.$db_name.'.RoleImplementations (group_id, role_id, object_auth_id) VALUES '.$role_values, @role_data);
    }
}


=item getObjectAuthIds(@group_ids)

Returns a reference to an array of object auth IDs which have permissions
involving the passed array of group IDs.

=cut

sub getObjectAuthIds {
    my $self = shift;
    my @group_ids = @_;

    my @auth_ids = ();

    return \@auth_ids unless scalar @group_ids;
    
    my $placeholders = join(',', map { '?' } @group_ids);
    
    my $db = Solstice::Database->new();
    my $db_name = Solstice::Configure->new()->getDBName();
        
    $db->readQuery('
        SELECT object_auth_id
        FROM '.$db_name.'.RoleImplementations
        WHERE group_id IN ('.$placeholders.')', @group_ids);

    while (my $data = $db->fetchRow()) {
        push @auth_ids, $data->{'object_auth_id'};
    }
    return \@auth_ids;
}


=back

=head2 Private Methods

=over 4

=cut


=item _addGroup($group)

Adds the group to the groups we are tracking.

=cut

sub _addGroup {
    my $self = shift;
    my $group = shift;

    if (!defined $group) {
        return FALSE;
    }
    $self->{'_groups'}->{$group->getID()} = $group;
}

sub _initFromHashRef {
    my $self = shift;
    my $data = shift;

    my $authz_id = $data->{'id'};
    my $roles = $data->{'roles'};

    return $self unless defined $authz_id || defined @$roles;

    foreach my $role_info (@$roles){
        my $group = $role_info->{'group'};
        my $role    = $role_info->{'role'};
        if(defined $group){
            $self->addRole($group, $role);
        }
    }
    $self->_setID($authz_id);
    return $self;
}
=item _init($authz)

Fills out the data for this authz manager.

=cut

sub _init {
    my $self = shift;
    my $authz_id = shift;

    $self->{_roles} = {};
    $self->{_groups} = {};
    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my %prior_roles;
    my %prior_groups;
    
    $db->readQuery('SELECT role_id, group_id
    FROM '.$db_name.'.RoleImplementations
    WHERE object_auth_id = ?', $authz_id);

    while (my $data = $db->fetchRow()) {
        my $role_id  = $data->{'role_id'};
        my $group_id = $data->{'group_id'};
        
        if (!defined $prior_roles{$role_id}) {
            my $role = Solstice::AuthZ::Role->new($role_id);
            $prior_roles{$role_id} = $role;
        }
        if (!defined $prior_groups{$group_id}) {
            my $group = Solstice::Group->new($group_id);
            $prior_groups{$group_id} = $group;
        }
        if (defined $prior_groups{$group_id}) {
            $self->addRole($prior_groups{$group_id}, $prior_roles{$role_id});
        }
    
    }

    $self->_setID($authz_id);
}
1;
__END__

=back

=head2 Modules Used

L<Solstice::AuthZ::Role|Solstice::AuthZ::Role>,
L<Solstice::Group|Solstice::Group>,
L<Model|Model>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3395 $



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

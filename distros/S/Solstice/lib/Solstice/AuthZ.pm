package Solstice::AuthZ;

# $Id: AuthZ.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::AuthZ - For making authorization queries about particular actions.

=head1 SYNOPSIS

  use Solstice::AuthZ;

  my $authz = Solstice::AuthZ->new();
  my $bool  = $authz->_canPerformAction(app_id, 'action_string');
  my $bool  = $authz->_hasNoRoles();
  
=head1 DESCRIPTION

A centralized interface for application permissions.  See https://satchmo.oep.washington.edu/wiki/wiki.pl?AuthZ for more details.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Service);

use Solstice::Database;
use Solstice::UserService;
use Solstice::Group;

use constant TRUE => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

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
    my $authz_id = shift;
    
    my $self = $obj->SUPER::new(@_);
    $self->_init($authz_id);
    
    return $self;
}

=item setIsOwner()

Tells the AuthZ object that the current user is the owner of the object, and all checks should return true.

=cut

sub setIsOwner {
    my $self = shift;
    $self->{_is_owner} = TRUE;
}

sub getID {
    my $self = shift;
    return $self->{_id};
}


=back

=head2 Private Methods

=over 4

=cut


=item _init($authz_id)

Load the permissions the currently logged in used has for the given authz_id.

=cut

sub _init {
    my $self = shift;
    my $id = shift;
    if (!defined $id or !$id) {
        return;
    }

    $self->_setID($id);

    my $prior_init = $self->get("init___$id");
    if (defined $prior_init and $prior_init == TRUE) {
        return;
    }

    my $user_service = Solstice::UserService->new();
    my $user = $user_service->getUser();

    if (!defined $user) {
        return;
    }

    my $db = Solstice::Database->new();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery('SELECT role_id, group_id
    FROM '.$db_name.'.RoleImplementations
    WHERE object_auth_id = ?', $id);

    my $valid_roles = '';
    my @role_data;
    while (my $data = $db->fetchRow()) {
        my $group = Solstice::Group->new($data->{'group_id'});
        if (defined $group) {
            if ($group->isMember($user)) {
                $valid_roles .= '?,';
                push @role_data, $data->{'role_id'};
            }
        }
    }
    
    if ($valid_roles) {
        chop $valid_roles;
        $db->readQuery('SELECT a.name, a.application_id
        FROM '.$db_name.'.Actions AS a, '.$db_name.'.RolePermissions AS rp
        WHERE a.action_id = rp.action_id AND rp.role_id IN ('. $valid_roles .')', @role_data);

        while (my $data = $db->fetchRow()) {
            $self->_setCanPerformAction($data->{'application_id'}, $data->{'name'});
        }
    }
    else {
        $self->_setHasNoRoles(TRUE);
    }
    $self->set("init___$id", TRUE);
}

=item _setHasNoRoles(BOOL)

Sets a boolean specifying whether this person has no roles.  Defaults to false.

=cut

sub _setHasNoRoles {
    my $self = shift;
    my $bool = shift;
    my $id   = $self->getID();
    $self->set("${id}___no_roles", $bool)
}

=item hasNoRoles()

Returns a bool specifying whether or not the user has no roles.

=cut

sub hasNoRoles {
    my $self = shift;
    my $id   = $self->getID();
    if ($self->{_is_owner}) {
        return FALSE;
    }
    my $value = $self->get("${id}___no_roles");
    if (defined $value and $value == 1) {
        return TRUE;
    }
    return FALSE;
}

=item _setCanPerformAction(app_id, 'action_string')

Sets the given action in the given app to be an allowed action.

This and _canPerformAction can probably implemented a little less crudely...

=cut

sub _setCanPerformAction {
    my $self = shift;
    my $app_id = shift;
    my $action = shift;
    my $id     = $self->getID();
    $self->set("${id}___${app_id}___${action}", 1);
}

=item _canPerformAction(app_id, 'action_string')

Returns TRUE or FALSE, depending on what the permission cache created in _init set for the given app_id and action_string.

=cut

sub _canPerformAction {
    my $self = shift;
    my $app_id = shift;
    my $action = shift;
    if ($self->{_is_owner}) {
        return TRUE;
    }
    my $id     = $self->getID();

    return FALSE unless $id && $action && $app_id;

    my $value = $self->get("${id}___${app_id}___${action}");
    if (defined $value and $value == TRUE) {
        return TRUE;
    }
    return FALSE;
}

sub _setID {
    my $self = shift;
    $self->{_id} = shift;
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Database|Solstice::Database>,
L<Solstice::Service|Solstice::Service>,
L<Solstice::UserService|Solstice::UserService>,
L<Solstice::Group|Solstice::Group>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



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

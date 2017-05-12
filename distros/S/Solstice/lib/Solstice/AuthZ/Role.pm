package Solstice::AuthZ::Role;

# $Id: Role.pm 3384 2006-05-17 21:57:05Z mcrawfor $

=head1 NAME

Solstice::AuthZ::Role - Models a group of allowed/disallowed actions.

=head1 SYNOPSIS

  use Action;

  my $model = Action->new();
  # The following accessors were created auto-magically by majere...

  my $obj = $model->getName();
  $model->setName($obj);

  my $obj = $model->getDescription();
  $model->setDescription($obj);

  my $obj = $model->getAppID();
  $model->setAppID($obj);

=head1 DESCRIPTION

Represents an Authz Action record.

=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::AuthZ::Action;
use Solstice::Database;
use Solstice::Model;
use Solstice::AuthZ::Factory;

our @ISA = qw(Solstice::Model);

our ($VERSION) = ('$Revision: 3384 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Model|Solstice::Model>

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

    $self->setSTID(0);
    $self->{_actions} = [];

    if($self->isValidHashRef($input)){
        $self->_initFromHashRef($input);
    }elsif(defined $input){
        $self->_init($input);
    }

    return $self;
}


sub getID{
    my $self = shift;
    return $self->{_id};
}

sub setID{
    my $self = shift;
    $self->{_id} = shift;
}

=item getName()

An accessor for _name.

=cut

sub getName {
    my $self = shift;
    return $self->{_name};
}

=item setName($obj)

An accessor for _name.

=cut

sub setName {
    my $self = shift;
    $self->{_name} = shift;
}

=item getSTID()

An accessor for _name.

=cut

sub getSTID {
    my $self = shift;
    return $self->{_stid};
}

=item setSTID($obj)

An accessor for _name.

=cut

sub setSTID {
    my $self = shift;
    $self->{_stid} = shift;
}

=item addAction

adds an action to the list of allowed permissions
=cut

sub addActions{
    my $self = shift;
    my @actions = @_;

    push @{$self->{_actions}}, @actions;
}

sub getActions{
    my $self = shift;
    wantarray ? return @{$self->{_actions}} : return $self->{_actions};
}

sub clearActions{
    my $self = shift;
    $self->{_actions} = [];
}


=back

=head2 Private Methods

=over 4

=cut


=item _init($id)

Sets up the object

=cut

sub _init{
    my $self = shift;
    my $original_id = shift;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery("SELECT role_id, name, person_id FROM ".$db_name.".Role WHERE role_id = ?",$original_id);

    my $data_ref = $db->fetchRow();
    return $self unless $data_ref;
    $self->_initFromHashRef($data_ref);
    return $self;
}

sub _initFromHashRef {
    my $self = shift;
    my $data_ref = shift;

    $self->setID($data_ref->{'role_id'});
    $self->setName($data_ref->{'name'});
    $self->setSTID($data_ref->{'person_id'});

    my $actions = Solstice::AuthZ::Factory->new()->createActionsByRole($self);

    $self->addActions(@$actions);

    return $self;
}

sub store {
    my $self = shift;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my $id            = $self->getID();
    my $name        = $self->getName();
    my $stid        = $self->getSTID();


    my $testid;
    if (defined $id) {
        $db->readQuery("SELECT role_id FROM ".$db_name.".Role WHERE role_id = ?",$id);
        $testid = $db->fetchRow()->{'role_id'};
    }

    if($testid){

        $db->writeQuery(
            "UPDATE ".$db_name.".Role SET
            name = ?,
            person_id = ?
            WHERE
            role_id = ?",$name,$stid,$id
        );

        $db->writeQuery("DELETE FROM ".$db_name.".RolePermissions WHERE role_id = ?", $id);

    }else{

        $db->writeQuery("INSERT INTO ".$db_name.".Role
            (name, person_id)
            values
            (?, ?)",$name,$stid);
        my $id = $db->getLastInsertID();

        $self->setID($id);
    }

    $db->writeLock($db_name.".RolePermissions");

    $id = $self->getID(); #incase of a new insert

    for my $action ($self->getActions()){
        $db->writeQuery("INSERT INTO ".$db_name.".RolePermissions (role_id, action_id) values (?,?)",$id,$action->getID());
    }

    $db->unlockTables();
}


sub delete{
    my $self = shift;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my $id = $self->getID();

    $db->writeQuery("DELETE FROM ".$db_name.".Role WHERE role_id = ?",$id);
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::AuthZ::Action|Solstice::AuthZ::Action>,
L<Solstice::Database|Solstice::Database>,
L<Solstice::Model|Solstice::Model>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3384 $



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

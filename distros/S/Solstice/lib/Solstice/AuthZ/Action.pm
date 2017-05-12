package Solstice::AuthZ::Action;

# $Id: Action.pm 3384 2006-05-17 21:57:05Z mcrawfor $

=head1 NAME

Solstice::AuthZ::Action - Models a specfic action within an application.

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

use Solstice::Database;
use Solstice::Configure;
use Solstice::Model;

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
    my $id = shift;

    my $self = $obj->SUPER::new(@_);

    my $ref = ref $id;
    if($ref eq 'HASH'){
        $self->_initByHash($id);
    }elsif($id){
        $self->_init($id);
    }

    return $self;
}


sub getID {
    my $self = shift;
    return $self->{_id};
}

sub setID {
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


=item getDescription()

An accessor for _description.

=cut

sub getDescription {
    my $self = shift;
    return $self->{_description};
}

=item setDescription($obj)

An accessor for _description.

=cut

sub setDescription {
    my $self = shift;
    $self->{_description} = shift;
}


=item getAppID()

An accessor for _app_i_d.

=cut

sub getAppID {
    my $self = shift;
    return $self->{_app_i_d};
}

=item setAppID($obj)

An accessor for _app_i_d.

=cut

sub setAppID {
    my $self = shift;
    $self->{_app_i_d} = shift;
}


=back

=head2 Private Methods

=over 4

=cut


=item _init($id)

Sets up the object

=cut

sub _init {
    my $self = shift;
    my $original_id = shift;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    $db->readQuery("SELECT action_id, name, description, application_id FROM ".$db_name.".Actions where action_id = ?",$original_id);

    my $data_ref = $db->fetchRow();
    $self->_initByHash($data_ref);
}


sub _initByHash {
    my $self = shift;
    my $data_ref = shift;

    $self->setID($data_ref->{'action_id'});
    $self->setAppID($data_ref->{'application_id'});
    $self->setName($data_ref->{'name'});
    $self->setDescription($data_ref->{'description'});
}

sub store {
    my $self = shift;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my $id            = $self->getID();
    my $name        = $self->getName();
    my $app_id        = $self->getAppID();
    my $description    = $self->getDescription();


    my $testid;
    if (defined $id) {
        $db->readQuery("SELECT action_id from ".$db_name.".Actions WHERE action_id = ?",$id);
        $testid = $db->fetchRow()->{'action_id'};
    }

    if($testid){

        $db->writeQuery(
            "UPDATE ".$db_name.".Actions SET
            name = ?,
            description = ?,
            application_id = ?
            WHERE
            action_id = ?",$name,$description,$app_id,$id);

    }else{

        $db->writeQuery("INSERT INTO ".$db_name.".Actions
            (name, description, application_id)
            values
            (?, ?, ?)",$name,$description,$app_id);
        my $id = $db->getLastInsertID($db_name.".Actions");

        $self->setID($id);
    }
}


sub delete {
    my $self = shift;

    my $db = new Solstice::Database();
    my $config = Solstice::Configure->new();
    my $db_name = $config->getDBName();

    my $id = $self->getID();

    $db->writeQuery("DELETE FROM ".$db_name.".Actions WHERE action_id = ?",$id);
}


1;
__END__

=back

=head2 Modules Used

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

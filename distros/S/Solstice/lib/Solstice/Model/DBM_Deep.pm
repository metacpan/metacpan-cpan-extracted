package Solstice::Model::DBM_Deep;

# $Id: Model.pm 2393 2005-07-18 17:12:40Z pmichaud $

=head1 NAME

Solstice::Model::DBM_Deep - An interface for DBM_Deep based models.

=head1 SYNOPSIS

# See L<Solstice::Model>.

=cut

=head1 DESCRIPTION

This module overrides _init and store, using DBM::Deep as a data storage engine.  It saves/loads everything that is in the accessor definition.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);
use DBM::Deep;
use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 2393 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new([$id])

Returns a new object.  If an id if passed in, it will be initialized.

=cut

sub new {
    my $class = shift;
    my $obj_id = shift;

    my $self = $class->SUPER::new(@_);

    if (defined $obj_id) {
        $self = $self->_initialize($obj_id);
    }

    return $self;
}

=item store()

Saves the object into DBM::Deep.

=cut

sub store {
    my $self = shift;

    my $id = $self->getID();

    if (!defined $id) {
        $id = $self->_generateID();
        $self->_setID($id);
    }

    # Hack a bit so we don't store persistence values... but we don't want to cause problems for people using them.
    my $old_persistence = $self->{'_persistence'};

    $self->clearPersistenceValues();

    my $db = $self->_getDB(); 
    $db->put($id, $self);

    $self->{'_persistence'} = $old_persistence;

    return TRUE;
}

=item delete()

Removes the object from the data store.

=cut

sub delete {
    my $self = shift;

    my $id = $self->getID();

    return FALSE unless defined $id;

    my $db = $self->_getDB();

    return $db->delete($id);
}


=item getAllIDs()

provides an arrayref of all the ids of this class

=cut

sub getAllIDs {

    my $self = shift;

    my $db = $self->_getDB();


    my @ids;
    my $key = $db->first_key();

    while ($key){
        push @ids, $key;
        $key = $db->next_key($key);
    }

    return \@ids;
}

sub getAll {
    my $self = shift;

    my $list = Solstice::List->new();
    for my $id (@{ $self->getAllIDs() }){
        $list->add($self->new($id));
    }
    return $list;

}


=back

=head2 Private Functions 

=over 4

=cut

=item _getDBPath()

Returns the full path to the object store.

=cut

sub _getDBPath {
    my $self = shift;

    my $ref = ref $self || $self;
    $ref =~ s/[^a-z]+/_/gi;
    
    my $data_root = $self->getConfigService()->getDataRoot();

    $data_root = "$data_root/model_dbm_deep_data/";
    $self->_dirCheck($data_root);

    return "$data_root/$ref.db";
}

=item _initialize($id)

Loads the object from DBM::Deep

=cut


sub _initialize {
    my $self = shift;
    my $id   = shift;

    my $db = $self->_getDB(); 
    $self = $db->get($id);

    return $self;
}

=item _getDB()

Returns the DBM::Deep object.

=cut

sub _getDB {
    my $self = shift;
    return DBM::Deep->new(
        file        => $self->_getDBPath(),
        autobless   => TRUE,
    );
}

=item _generateID()

This will generate an id string, if an object doesn't have an existing id.

=cut

sub _generateID {
    my $self = shift;

    my $ref = ref $self;
    my $rand1 = rand();
    my $rand2 = rand();
    my $time  = time;

    return "$ref-$rand1-$rand2-$time";
}

1;

__END__

=back

=head2 Modules Used

L<DBM::Deep|DBM::Deep>,
L<Solstice::Model|Solstice::Model>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2393 $

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

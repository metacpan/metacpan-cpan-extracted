package Solstice::Resource;

# $Id: Resource.pm 851 2005-11-09 22:37:27Z jlaney $

=head1 NAME

Solstice::Resource - A superclass for all Solstice::Resource objects. 

=head1 SYNOPSIS
  
  package Solstice::Resource;

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw( Solstice::Tree Solstice::Model );

use Solstice::DateTime;
use Solstice::Factory::Person;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 851 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Tree|Solstice::Tree>,
L<Solstice::Model|Solstice::Model>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructor; should only be called by a subclass.
Returns a Solstice::Resource object.

=cut

sub new {
    my $class = shift;
    my $input = shift;
    my $self = $class->SUPER::new(@_);

    # Explicitly call Solstice::Model->_createAttributes(), because of
    # multiple inheritance.
    $self->_initAttributes();

    if (defined $input and $self->_isValidHashRef($input)) {
        $self->_initFromHash($input) or return undef;
    } elsif (defined $input) {
        $self->_initFromID($input) or return undef;
    } else {
        $self->_initEmpty() or return undef;
    }
    return $self;
}

=item setName($name)

Sets the name of a resource, if it hasn't already been set.

=cut

sub setName {
    my $self = shift;
    my $name = shift;

    if (defined (my $name = $self->getName())) {
        $self->warn("Name already set to $name, use move().");
        return FALSE;
    }
    return $self->_setName($name);
}

=item isContainer()

Return TRUE if the resource is a container, FALSE otherwise.

=cut

sub isContainer {
    return FALSE;
}

=item isValidPath($path)

Return TRUE if the passed $path is valid, FALSE otherwise. 

=cut

sub isValidPath {
    my $self = shift;
    my $path = shift;
    return FALSE unless defined $path;
    return TRUE;
}

=item getPath()

Finds the path of the resource, recursing up the tree to generate it.

=cut

sub getPath {
    my $self = shift;

    my $name = $self->getName();

    return $name if $self->isRoot();

    return $self->getParent()->getPath().'/'.$name;
}

=item getOwner()

Optimized for loading owner object only when called on.

=cut

sub getOwner {
    my $self = shift;
    if (!defined $self->_getOwner() && defined $self->_getOwnerID()) {
        my $pf = Solstice::Factory::Person->new();
        $self->_setOwner($pf->createByID($self->_getOwnerID()));
    }
    return $self->_getOwner();
}

=item getCreationDate()

Returns a Solstice::DateTime that represents the date the Resource 
was first stored.
    
=cut

sub getCreationDate {
    my $self = shift;
    if (!defined $self->_getCreationDate() && defined $self->_getCreationDateStr()) { 
        $self->_setCreationDate(Solstice::DateTime->new($self->_getCreationDateStr()));
    } 
    return $self->_getCreationDate();
}

=item getModificationDate()

Returns a Solstice::DateTime that represents the date the Resource 
was last stored, with changes.

=cut

sub getModificationDate {
    my $self = shift;
    if (!defined $self->_getModificationDate() && defined $self->_getModificationDateStr()) {
        $self->_setModificationDate(Solstice::DateTime->new($self->_getModificationDateStr()));
    }
    return $self->_getModificationDate();
}


=item move($path)

Move the resource to parent $path.

=cut

sub move {
    my $self = shift;
    my $path = shift;

    $self->_setTargetPath($path);
    $self->_taint();
    return TRUE;
}

=item delete()

Delete the resource.

=cut

sub delete {
    my $self = shift;
    $self->_deprecate();
    return TRUE;
}

=item clone()

Returns a clone of the resource, with the name stripped and a 
source path added.

=cut

sub clone {
    my $self = shift;

    my $package = $self->getClassName();

    my $clone = $package->new();

    $clone->setOwner($self->getOwner());
    $clone->_setSourcePath($self->getPath());
    $clone->_setSize($self->getSize());
    $clone->_setCreationDate(Solstice::DateTime->new(time));
    $clone->_setModificationDate(Solstice::DateTime->new(time));

    return $clone;
}

=item store([$params])

Stores the resource.  Brokers work off to various methods for moving, copying deleting, storing content, and so on.

=cut

sub store {
    my $self = shift;

    if ($self->_isDeprecated()) {
        return $self->_delete();
    } elsif (defined $self->getTargetPath()) {
        return $self->_move();
    } elsif (defined $self->getSourcePath()) {
        return $self->_copy();
    } elsif ($self->_isTainted()) {
        return $self->_store(@_);
    } else {
        return FALSE;
    }
}

=item equals($resource)

Returns TRUE if the passed $resource represents the same resource
as $self, FALSE otherwise.

=cut

sub equals {
    my $self = shift;
    my $resource = shift;

    return FALSE unless defined $resource;

    return FALSE unless $resource->getClassName() eq $self->getClassName();

    return FALSE unless (defined $resource->getID() && defined $self->getID() &&
        $resource->getID() eq $self->getID());
 
    return TRUE;
}

=item isValidName($name)

Returns TRUE if passed $name is valid for the resource, FALSE 
otherwise.  The default implementation is very strict, and should 
probably be overridden in a subclass.

=cut

sub isValidName {
    my $self = shift;
    my $name = shift;

    return TRUE if $name =~ /^[^\.][\w\-\.]{0,255}$/;
    return FALSE;
}

=back

=head2 Private Methods

=over 4

=item _initFromID()

=cut

sub _initFromID {
    my $self = shift;
    warn ref($self) . "->_initFromID(): Not implemented\n";
    return FALSE;
}

=item _initFromHash(\%params)

=cut

sub _initFromHash {
    my $self = shift;
    my $params = shift;

    # If person object not defined, it can be created later,
    # as long as person_id is passed...    
    unless (defined $params->{'owner'}) {
        return FALSE unless defined $params->{'person_id'};
        $self->_setOwnerID($params->{'person_id'});
    }
    
    $self->_setID($params->{'id'});
    $self->_setOwner($params->{'owner'});
    $self->_setPath($params->{'path'});
    $self->_setName($params->{'name'});
    $self->_setSize($params->{'content_length'} || $params->{'size'});

    # Hash inits set date strings into the resource object, to
    # be converted into DateTime objects later
    $self->_setCreationDateStr($params->{'creation_date'});
    $self->_setModificationDateStr($params->{'modification_date'});

    return TRUE;
}

=item _initEmpty()

=cut

sub _initEmpty {
    my $self = shift;
    return TRUE;
}

=item _store()

Internal store, implemented by a subclass.

=cut

sub _store {
    my $self = shift;
    warn ref($self) . "->_store(): Not implemented\n";
    return FALSE;
}

=item _copy()

The actual copy, called by store.

=cut

sub _copy {
    my $self = shift;
    warn ref($self) . "->_copy(): Not implemented\n";
    return FALSE;
}

=item _move()

The actual move, called by store.

=cut

sub _move {
    my $self = shift;
    warn ref($self) . "->_move(): Not implemented\n";
    return FALSE;
}

=item _delete()

The actual delete, called by store.

=cut

sub _delete {
    my $self = shift;
    warn ref($self) . "->_delete(): Not implemented\n";
    return FALSE;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Name',
            key  => '_name',
            type => 'String',
            taint => TRUE,
        },
        {
            name => 'Owner',
            key  => '_owner',
            type => 'Person',
            taint => TRUE,
            private_get => TRUE,
        },
        {
            name => 'OwnerID',
            key  => '_owner_id',
            type => 'Integer',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'Size',
            key  => '_size',
            type => 'Float',
            private_set => TRUE,
        },
        {
            name => 'Path',
            key  => '_path',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'CreationDate',
            key  => '_creation_date',
            type => 'DateTime',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'ModificationDate',
            key  => '_modification_date',
            type => 'DateTime',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'CreationDateStr',
            key  => '_creation_date_str',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        },
        {
            name => 'ModificationDateStr',
            key  => '_modification_date_str',
            type => 'String',
            private_set => TRUE,
            private_get => TRUE,
        }, 
        {
            name => 'SourceID',
            key  => '_source_id',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'SourcePath',
            key  => '_source_path',
            type => 'String',
            private_set => TRUE,
        },
        {
            name => 'TargetPath',
            key  => '_target_path',
            type => 'String',
            private_set => TRUE,
        },
    ];
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Model|Solstice::Model>.

L<Carp|Carp>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 851 $ 

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

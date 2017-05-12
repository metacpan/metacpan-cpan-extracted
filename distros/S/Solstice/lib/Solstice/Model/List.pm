package Solstice::Model::List;

# $Id: List.pm 83 2006-03-14 06:51:35Z jlaney $

=head1 NAME

Solstice::Model::List - Superclass for classes that need to be both a List and a Model.

=head1 SYNOPSIS

    use Solstice::Model::List;; 

    my $model = Solstice::Model::List->new();

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw( Solstice::Model Solstice::List );

our ($VERSION) = ('$Revision: 2065 $' =~ /^\$Revision:\s*([\d.]*)/);

use constant TRUE    => 1;
use constant FALSE   => 0;
use constant SUCCESS => 1;
use constant FAIL    => 0;

=head2 Export

None by default.

=head2 Methods

=over 4

=item new ()

Creates and returns an empty Solstice::Model::List object.

=cut

sub new {
    my ($class) = @_;
    
    my $self = $class->SUPER::new();
    $self->_clear();

    return $self;
}

=item clear()

Removes all entries from the List object.

=cut

sub clear {
    my ($self) = @_;
    $self->_listRead();
    $self->_listChanged();
    return $self->Solstice::List::clear();
}

=item reverse()

Reverse the order of the entries in the List.

=cut

sub reverse {
    my ($self) = @_;
    $self->_listRead();
    $self->_listChanged();
    return $self->Solstice::List::reverse();
}

=item push($element)

Adds an element to the end of the List.

=cut

sub push {
    my ($self, $element) = @_;
    $self->_listRead();
    $self->_listChanged();
    return $self->Solstice::List::push($element);
}

=item pop()

Remove the last element in the List and return it.

=cut

sub pop {
    my ($self) = @_;
    $self->_listRead();
    $self->_listChanged();
    return $self->Solstice::List::pop();
}

=item unshift($element)

Adds an element to the front of the List.

=cut

sub unshift {
    my ($self, $element) = @_;
    $self->_listRead();
    $self->_listChanged();
    return $self->Solstice::List::unshift($element);
}

=item shift()

Remove the first element in the List and return it.

=cut

sub shift {
    my ($self) = @_;
    $self->_listRead();
    $self->_listChanged();
    return $self->Solstice::List::shift();
}

=item add ([$index,] $element)

Adds an element to the List. If no index is given it will be added to the 
end of the List, otherwise it will be placed at the index given, and the 
other elements will be shifted out of the way. Passing $index equal to the 
list size is also permissible. It is 0 indexed.

=cut

sub add {
    my $self = CORE::shift;
    $self->_listRead();
    $self->onAdd();
    my $status = $self->Solstice::List::add(@_);
    $self->_listChanged() if $status;
    return $status;
}

sub onAdd {
    return TRUE;
}

=item addList($list)

=cut

sub addList {
    my $self = CORE::shift;
    $self->_listRead();
    my $status = $self->Solstice::List::addList(@_);
    $self->_listChanged() if $status;
    return $status;
}

=item replace($index, $element)

Replace an element in the List. It is 0 indexed. If successful, the
replaced element is returned.

=cut

sub replace {
    my ($self, $index, $element) = @_;
    $self->_listRead();
    $self->onReplace();
    my $return = $self->Solstice::List::replace($index, $element);
    $self->_listChanged();
    return $return;
}

sub onReplace {
    return TRUE;
}

sub exists {
    my ($self, $index) = @_;
    $self->_listRead();
    return $self->Solstice::List::exists($index);
}


sub get {
    my ($self, $index) = @_;
    $self->_listRead();
    return $self->Solstice::List::get($index);
}

sub getAll {
    my ($self) = @_;
    $self->_listRead();
    return $self->Solstice::List::getAll();
}


sub isEmpty {
    my ($self) = @_;
    $self->_listRead();
    return $self->Solstice::List::isEmpty();
}

sub size {
    my ($self) = @_;
    $self->_listRead();
    return $self->Solstice::List::size();
}

sub iterator {
    my ($self) = @_;
    $self->_listRead();
    return $self->Solstice::List::iterator();
}

=item move ($oldindex, $newindex)

This will move an element from one position in the List to another. It is 0 indexed.  
Note: This will not reset any iterators, so there may be some confusion if you 
iterate over a List you are still manipulating.

=cut

sub move {
    my ($self, $oldindex, $newindex) = @_;
    $self->_listRead();
    $self->onMove();
    my $status = $self->Solstice::List::move($oldindex, $newindex);
    $self->_listChanged() if $status;
    return $status;
}
=item onMove

=cut

sub onMove {
    return TRUE;
}    
=item remove ($index)

This will remove an element from the List, at the index given. It is 0 indexed.
If successful, the removed element is returned.

=cut

sub remove {
    my ($self, $index) = @_;
    $self->_listRead();
    $self->onRemove($index);
    my $return = $self->Solstice::List::remove($index);
    $self->_listChanged();
    return $return; 
}

=item onRemove

This is an empty method meant for overriding by subclasses

=cut

sub onRemove {
    return TRUE;
}

=back

=head2 Private Methods

=over 4

=item _clear()

=cut

sub _clear {
    my $self = CORE::shift;
    return $self->Solstice::List::clear();
}

=item _add([$position,] $element)

=cut

sub _add {
    my $self = CORE::shift;
    return $self->Solstice::List::add(@_);
}

=item _addList($list)

=cut

sub _addList {
    my $self = CORE::shift;
    return $self->Solstice::List::addList(@_);
}

=item _listChanged()

=cut

sub _listChanged {
    my $self = CORE::shift;
    $self->_taint();
}

sub _listRead {
    #override me!
}


1;

__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 83 $



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

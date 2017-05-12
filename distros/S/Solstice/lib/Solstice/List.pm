package Solstice::List;

# $Id: List.pm 2065 2005-03-05 01:16:48Z tleffler $

=head1 NAME

Solstice::List - A basic list object.

=head1 SYNOPSIS

  use List;

  my $list = new List;

  $list->add($element);
  $list->add($position, $element);
  $element = $list->get($position);
  $list->remove($position);
  $list->move($oldindex, $newindex);
  $isempty = $list->isEmpty();
  my $size = $list->size();
  $list->clear();

  my $iterator = $list->iterator();
  while ($iterator->hasNext()) {
    my $element = $iterator->next();
  }

=head1 DESCRIPTION

Provides a set of functionality for creating and manipulating lists.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Carp qw(confess);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 2065 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new ([$list])

Creates and returns an empty List object. If passed, $list can be 
either a Solstice::List object, or a reference to an array.

=cut

sub new {
    my ($class, $input) = @_;
    
    my $self = $class->SUPER::new();
    $self->Solstice::List::_init($input);

    return $self;
}

=item clear()

Removes all entries from the List object.

=cut

sub clear {
    my ($self) = @_;
    @{$self->{'_list'}} = ();
    return TRUE;
}

=item reverse()

Reverse the order of the entries in the List.

=cut

sub reverse {
    my ($self) = @_;
    my @list = CORE::reverse(@{$self->{'_list'}});
    $self->{'_list'} = \@list;
    return TRUE;
}

=item push($element)

Adds an element to the end of the List.

=cut

sub push {
    my ($self, $element) = @_;
    CORE::push(@{$self->{'_list'}}, $element);
}

=item pop()

Remove the last element in the List and return it.

=cut

sub pop {
    my ($self) = @_;
    return CORE::pop(@{$self->{'_list'}});
}

=item unshift($element)

Adds an element to the front of the List.

=cut

sub unshift {
    my ($self, $element) = @_;
    CORE::unshift(@{$self->{'_list'}}, $element);
}

=item shift()

Remove the first element in the List and return it.

=cut

sub shift {
    my ($self) = @_;
    return CORE::shift(@{$self->{'_list'}});
}

=item add ([$index,] $element)

Adds an element to the List. If no index is given it will be added to the 
end of the List, otherwise it will be placed at the index given, and the 
other elements will be shifted out of the way. Passing $index equal to the 
list size is also permissible. It is 0 indexed.

=cut

sub add {
    my $self = CORE::shift;
    my ($index, $element);

    if ($#_ == 0) { 
        $index   = $self->size();
        $element = CORE::shift;
    
    } elsif ($#_ == 1) {
        $index   = CORE::shift;
        $element = CORE::shift;
        my $size = $self->size();
        
        unless ($self->exists($index) or $index == $size) {
            my $limit = $size + 1;
            confess "add(): Index $index is not between 0 and the allowed maximum ($limit)";
        }
        
        @{$self->{'_list'}}[($index+1)..($size)] = @{$self->{'_list'}}[($index)..($size-1)];
    
    } else {
        confess "add(): Requires at least one argument";
    }

    $self->{'_list'}->[$index] = $element;
    return TRUE;
}

=item addList($list)

Append items in $list to the List. $list can be either a Solstice::List 
object, or a reference to an array.

=cut

sub addList {
    my ($self, $list) = @_;

    return FALSE unless defined $list;
    
    if ($self->isValidObject($list, 'Solstice::List')) {
        $list = $list->getAll();
    } else {
        return FALSE unless $self->isValidArrayRef($list);
    }
    
    CORE::push(@{$self->{'_list'}}, @$list);
    
    return TRUE;
}

=item replace($index, $element)

Replace an element in the List. It is 0 indexed. if successful, the replaced
element is returned.

=cut

sub replace {
    my ($self, $index, $element) = @_;

    confess "replace(): Requires two arguments"
        unless (defined $index and defined $element);
    
    unless ($self->exists($index)) {
        my $size = $self->size();
        confess "replace(): Index $index is not between 0 and the list size ($size)";
    }

    my $return = $self->{'_list'}->[$index];
    
    $self->{'_list'}->[$index] = $element;
    
    return $return;
}

=item contains($element)

Not implemented.

=cut

sub contains {
    confess "contains(): unimplemented";
}

=item exists($index)

Returns TRUE if the passed $index exists in the List, FALSE otherwise.
It is 0 indexed.

=cut

sub exists {
    my ($self, $index) = @_;
    return FALSE unless (defined $index and $index =~ /^\d+$/ and scalar @{$self->{'_list'}} > $index);
}

=item get($index)

Returns the element in the List at the given index. It is 0 indexed.

=cut

sub get {
    my ($self, $index) = @_;

    unless ($self->exists($index)) {
        my $size = $self->size();
        confess "get(): Index $index is not between 0 and the list size ($size)";
    }
    return $self->{'_list'}->[$index];
}

=item getAll()

Returns the List.

=cut

sub getAll {
    my ($self) = @_;
    return $self->{'_list'};
}

=item indexOf ($element)

Not implemented.

=cut

sub indexOf {
    confess "indexOf(): unimplemented";
}

=item isEmpty ()

Returns a boolean describing whether the internal List array is empty.

=cut

sub isEmpty {
    my ($self) = @_;
    return !$self->size();
}

=item lastIndexOf ($element)

Not implemented.

=cut

sub lastIndexOf {
    confess "lastIndexOf(): unimplemented";
}

=item size ()

Returns the size of the internal List. This is also the index of the 'next'
position that an element can be added to, if you want to explicitly place 
it at the end of the List.

=cut

sub size {
    my ($self) = @_;
    return scalar @{$self->{'_list'}};
}

=item subList ($from, $to)

Returns a view of the portion of this List between the specified fromIndex, 
inclusive, and toIndex, exclusive

Not implemented.

=cut

sub subList {
    confess "subList(): unimplemented";
}

=item move ($oldindex, $newindex)

This will move an element from one position in the List to another. It is 0 indexed.  
Note: This will not reset any iterators, so there may be some confusion if you 
iterate over a List you are still manipulating.

=cut

sub move {
    my ($self, $oldindex, $newindex) = @_;
    my $size = $self->size();

    unless ($self->exists($oldindex)) {
        confess "move(): Source index $oldindex is not between 0 and the list size ($size)";
    }

    unless ($self->exists($newindex)) {
        confess "move(): Target index $newindex is not between 0 and the list size ($size)";
    }
    
    my $element;
    if ($oldindex == $size) {
        # If the element is at the end, just pop it.
        $element = CORE::pop(@{$self->{'_list'}});
    } else {
        # The harder case, where the array gets manipulated, and then pop the last element
        $element = $self->{'_list'}->[$oldindex];
        @{$self->{'_list'}}[($oldindex)..($size-1)] = @{$self->{'_list'}}[($oldindex+1)..($size)];
        CORE::pop(@{$self->{'_list'}});
    }
    # Now put the element back in it's proper place.
    # Easy if it's at the end of the array...
    if ($newindex == $size) {
        CORE::push(@{$self->{'_list'}}, $element);
    } else {
        $size = $self->size(); # List size has changed
        @{$self->{'_list'}}[($newindex + 1)..($size)] = @{$self->{'_list'}}[($newindex)..($size-1)];
        $self->{'_list'}[$newindex] = $element;
    }
    return TRUE;
}

=item remove ($index)

This will remove an element from the List, at the index given. It is 0 indexed.
If successful, the removed element is returned.

=cut

sub remove {
    my ($self, $index) = @_;
    my $size = $self->size();

    unless ($self->exists($index)) {
        confess "remove(): Index $index is not between 0 and the list size ($size)";
    }
    
    my $element;
    if ($index == $size) {
        # If the element is at the end, just pop it.
        $element = CORE::pop(@{$self->{'_list'}});
    } else {
        # Manipulate the array, and then pop the last element
        $element = $self->{'_list'}->[$index];
        @{$self->{'_list'}}[($index)..($size-1)] = @{$self->{'_list'}}[($index+1)..($size)];
        CORE::pop(@{$self->{'_list'}});
    }
    return $element; 
}

=item iterator ()

Creates and returns a new iterator over the List.

=cut

sub iterator {
    my ($self) = @_;
    return Solstice::List::Iterator->new($self);
}

=back

=head2 Private Methods

=over 4

=item _init([$input])

Initialize the List by clearing it.

=cut

sub _init {
    my ($self, $input) = @_;
    
    $self->Solstice::List::clear();
    $self->addList($input) if defined $input; 
    
    return TRUE;
}

=item _getDataArray()

Private method for the iterator to use when sorting.

=cut

sub _getDataArray {
    my ($self) = @_;
    return $self->{'_list'};
}

=item _setDataArray(\@data)

Private method for the iterator to use when sorting.

=cut

sub _setDataArray {
    my ($self, $list) = @_;
    $self->{'_list'} = $list;
}


package Solstice::List::Iterator;

use constant TRUE  => 1;
use constant FALSE => 0;

=item List::Iterator::new ($list)

Creates and returns a new iterator over the list.

=cut

sub new {
    my ($obj, $list) = @_;

    confess("Iterator::new(): Requires a List object") unless (defined $list and $list->isa('Solstice::List'));

    my $self = bless {
        _list  => $list,
        _index => 0,
    }, $obj;

    return $self;
}

=item List::Iterator::sort([$anonymous_sub_ref])

Sorts the values that will come out of the iterator. Resets the position of 
the iterator.

=cut

sub sort {
    my ($self, $sort_ref) = @_;

    my @new_data;

    if (defined $sort_ref) {
        # $a and $b are package variables, so we want to copy $a and $b 
        # into the namespace of the caller. Since we're doing this work 
        # for every sort call, we had to make a block based sort instead 
        # of a usersub sort, and so we had to explicitely call our sorting 
        # subroutine reference.  
        my $calling_package = (caller)[0];
        { 
            no strict 'refs'; ## no critic
            @new_data = CORE::sort { ${"${calling_package}::a"} = $a; ${"${calling_package}::b"} = $b; &$sort_ref($a, $b); } @{$self->{'_list'}->_getDataArray()};
        }
    }
    else {
        @new_data = CORE::sort @{$self->{'_list'}->_getDataArray()};
    }

    my $package = ref $self->{'_list'};
    my $list = $package->new();
    $list->_setDataArray(\@new_data);

    $self->{'_list'} = $list;
    $self->{'_index'} = 0;

    return TRUE;
}

=item List::Iterator::hasNext ()

Returns a boolean describing whether there is another element in the list 
after the current cursor position.

=cut

sub hasNext {
    my ($self) = @_;
    return $self->{'_index'} < $self->{'_list'}->size();
}

=item List::Iterator::next ()

Returns the next element in the list, and increments the cursor.

=cut

sub next {
    my ($self) = @_; 
    return undef if $self->{'_index'} >= $self->{'_list'}->size() || (defined $self->{'_end_index'} && $self->{'_index'} >= $self->{'_end_index'});
    return $self->{'_list'}->get($self->{'_index'}++);
}

=item List::Iterator::index ()

Returns the current cursor position.

=cut

sub index {
    my ($self) = @_;
    return $self->{'_index'} ? $self->{'_index'} - 1 : $self->{'_index'};
}

=item List::Iterator::setStartIndex ()

Moves the pointer of the list to the given position

=cut
sub setStartIndex {
    my $self = shift;
    my $start_index = shift;
    
    return unless defined $start_index;

    $self->{'_index'} = $start_index if $start_index < $self->{'_list'}->size() && $start_index >= 0;
}

=item List::Iterator::setEndIndex ()

Sets a cutoff position at which the iterator will stop looping

=cut
sub setEndIndex {
    my $self = shift;
    my $end_index = shift;

    return unless defined $end_index;

    $self->{'_end_index'} = $end_index if $end_index < $self->{'_list'}->size() && $end_index >= 0;
}

1;

__END__

=back

=head2 Modules Used

L<Carp|Carp>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2065 $ 



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

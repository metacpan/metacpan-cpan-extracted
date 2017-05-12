package Solstice::Stack;

# $Id: List.pm 2065 2005-03-05 01:16:48Z tleffler $

=head1 NAME

Solstice::Stack - A basic stack object.

=head1 SYNOPSIS

  use Solstice::Stack;

  my $stack = new Solstice::Stack;

  # Push an element onto the stack
  $stack->push($element);
  
  # Remove the last element in the stack, and return it
  $element = $stack->pop();

  # Return the last element in the stack
  $element = $stack->top();

  # Clear the stack
  $stack->clear();

  my $iterator = $list->iterator();
  while ($iterator->hasNext()) {
    my $element = $iterator->next();
  }

=head1 DESCRIPTION

Provides a set of functionality for creating and manipulating a stack.

=cut

use 5.006_000;
use strict;
use warnings;
use Carp qw(confess);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 2065 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new ()

Creates and returns an empty Solstice::Stack object.

=cut

sub new {
    my ($obj) = @_;
    
    my $self = bless {}, $obj;
    $self->Solstice::Stack::_init(@_);

    return $self;
}

=item clear()

Removes all entries from the Stack object.

=cut

sub clear {
    my ($self) = @_;
    @{$self->{'_stack'}} = ();
    return TRUE;
}

=item push($element)

Adds an element to the end of the Stack.

=cut

sub push {
    my ($self, $element) = @_;
    CORE::push(@{$self->{'_stack'}}, $element);
}

=item pop()

Remove the last element in the Stack and return it.

=cut

sub pop {
    my ($self) = @_;
    return CORE::pop(@{$self->{'_stack'}});
}

=item top()

Returns the last element in the Stack, without removing it.

=cut

sub top {
    my ($self) = @_;
    return $self->{'_stack'}->[-1];
}

=item isEmpty()

Returns a boolean describing whether the internal Stack array is empty.

=cut

sub isEmpty {
    my ($self) = @_;
    return scalar(@{$self->{'_stack'}}) ? FALSE : TRUE;
}

=item _init()

Initialize the Stack by clearing it.

=cut

sub _init {
    my ($self) = @_;
    
    $self->Solstice::Stack::clear();
    
    return TRUE;
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

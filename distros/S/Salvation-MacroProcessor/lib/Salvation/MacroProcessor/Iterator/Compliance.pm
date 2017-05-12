use strict;

package Salvation::MacroProcessor::Iterator::Compliance;

use Moose::Role;

requires 'first', 'last', 'seek', 'next', 'count', 'to_start', 'to_end', '__position', 'prev';

no Moose::Role;

-1;

__END__

# ABSTRACT: L<Salvation::MacroProcessor::Iterator>-compatible iterator interface

=pod

=head1 NAME

Salvation::MacroProcessor::Iterator::Compliance - L<Salvation::MacroProcessor::Iterator>-compatible iterator interface

=head1 REQUIRES

L<Moose> 

=head1 METHODS

Following methods should be implemented by a class in order to be compatible with L<Salvation::MacroProcessor::Iterator>.

=head2 first

 $object -> first()

Returns first element of a list.

=head2 last

 $object -> last()

Returns last element of a list.

=head2 seek

 $object -> seek( $position )

Sets position of an iterator to C<$position>.

=head2 next

 $object -> next()

Returns element at current position, then increases position by one.

=head2 count

 $object -> count()

Returns elements count.

=head2 to_start

 $object -> to_start()

Sets position of an iterator to start.

=head2 to_end

 $object -> to_end()

Sets position of an iterator to end.

=head2 __position

 $object -> __position()

Returns current position of an iterator.

=head2 prev

 $object -> prev()

Returns element at current position, then decreases position by one.

=cut


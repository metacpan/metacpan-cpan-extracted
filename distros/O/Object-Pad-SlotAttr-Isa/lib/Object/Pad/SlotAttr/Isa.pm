#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::SlotAttr::Isa 0.01;

use v5.14;
use warnings;

use Object::Pad 0.51;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::SlotAttr::Isa> - apply class type constraints to C<Object::Pad> slots

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::SlotAttr::Isa;

   class ListNode {
      has $next :param :reader :writer :Isa(ListNode) = undef;
   }

   my $first = ListNode->new();
   my $second = ListNode->new(next => $first);

   # This will fail
   my $third = ListNode->new(next => "something else");

   # This will fail
   $second->set_next("another thing");

=head1 DESCRIPTION

This module provides a third-party slot attribute for L<Object::Pad>-based
classes, which declares that values assigned to the slot must conform to a
given object type.

B<WARNING> The ability for L<Object::Pad> to take third-party slot attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

=head1 SLOT ATTRIBUTES

=head2 :Isa

   has $slot :Isa(CLASSNAME) ...;

Declares that any value assigned to the slot must be an object reference, and
must be derived from the named class. Attempts to assign a non-conforming
value, such as a non-reference, or reference to a class not derived from that
named, will throw an exception, and the slot value will not be modified.

This type constraint is applied whenever the slot itself is assigned to,
whether that is from C<:param> initialisation, invoking a C<:writer> or
C<:mutator> accessor, or direct assignment into the slot variable by method
code within the class.

=cut

sub import
{
   $^H{"Object::Pad::SlotAttr::Isa/Isa"}++;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Object::Pad::SlotAttr::Trigger 0.04;

use v5.14;
use warnings;

use Object::Pad 0.50;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::SlotAttr::Trigger> - invoke an instance method after a C<:writer> accessor

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::SlotAttr::Trigger;

   class Label {
      has $title :param :reader :writer :Trigger(redraw);

      method redraw {
         ...
      }
   }

   my $label = Label->new( text => "Something" );

   $label->set_label( "New text here" );
   # $label->redraw is automatically invoked

=head1 DESCRIPTION

This module provides a third-party slot attribute for L<Object::Pad>-based
classes, which declares that a named instance method shall be invoked after
a generated C<:writer> accessor method is called.

B<WARNING> The ability for L<Object::Pad> to take third-party slot attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

=head1 SLOT ATTRIBUTES

=head2 :Trigger

   has $slot :writer :Trigger(NAME) ...;

Declares that the accessor method generated for the slot by the C<:writer>
attribute will invoke the method named by the C<:Trigger> attribute, after the
new value has been stored into the slot itself. This method is invoked with no
additional arguments, in void context.

Note that this only applies to the generated accessor method. It does not
apply to direct modifications of the slot variable by method code within the
class itself.

=cut

sub import
{
   $^H{"Object::Pad::SlotAttr::Trigger/Trigger"}++;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package Object::Pad::FieldAttr::Trigger 0.07;

use v5.14;
use warnings;

use Object::Pad 0.66;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::FieldAttr::Trigger> - invoke an instance method after a C<:writer> accessor

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::FieldAttr::Trigger;

   class Label {
      field $title :param :reader :writer :Trigger(redraw);

      method redraw {
         ...
      }
   }

   my $label = Label->new( text => "Something" );

   $label->set_label( "New text here" );
   # $label->redraw is automatically invoked

=head1 DESCRIPTION

This module provides a third-party field attribute for L<Object::Pad>-based
classes, which declares that a named instance method shall be invoked after
a generated C<:writer> accessor method is called.

B<WARNING> The ability for L<Object::Pad> to take third-party field attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

=head1 FIELD ATTRIBUTES

=head2 :Trigger

   field $name :writer :Trigger(NAME) ...;

Declares that the accessor method generated for the field by the C<:writer>
attribute will invoke the method named by the C<:Trigger> attribute, after the
new value has been stored into the field itself. This method is invoked with
no additional arguments, in void context.

Note that this only applies to the generated accessor method. It does not
apply to direct modifications of the field variable by method code within the
class itself.

=cut

sub import
{
   $^H{"Object::Pad::FieldAttr::Trigger/Trigger"}++;
}

sub unimport
{
   delete $^H{"Object::Pad::FieldAttr::Trigger/Trigger"};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

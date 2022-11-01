#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.70 ':experimental(adjust_params)';

package Tangence::Meta::Method 0.30;
class Tangence::Meta::Method :strict(params);

=head1 NAME

C<Tangence::Meta::Method> - structure representing one C<Tangence> method

=head1 DESCRIPTION

This data structure object stores information about one L<Tangence> class
method. Once constructed, such objects are immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $method = Tangence::Meta::Method->new( %args )

Returns a new instance initialised by the given arguments.

=over 8

=item class => Tangence::Meta::Class

Reference to the containing class

=item name => STRING

Name of the method

=item arguments => ARRAY

Optional ARRAY reference containing arguments as
L<Tangence::Meta::Argument> references.

=item ret => STRING

Optional string giving the return value type as a L<Tangence::Meta::Type>
reference

=back

=cut

field $class :param :weak :reader;
field $name  :param       :reader;
field @arguments;
field $ret   :param       :reader;

ADJUST :params (
   :$arguments = undef,
) {
   @arguments = $arguments->@* if $arguments;
}

=head1 ACCESSORS

=cut

=head2 class

   $class = $method->class

Returns the class the method is a member of

=cut

=head2 name

   $name = $method->name

Returns the name of the class

=cut

=head2 arguments

   @arguments = $method->arguments

Return the arguments in a list of L<Tangence::Meta::Argument> references.

=cut

method arguments { @arguments }

=head2 argtype

   @argtypes = $method->argtypes

Return the argument types in a list of L<Tangence::Meta::Type> references.

=cut

method argtypes
{
   return map { $_->type } @arguments;
}

=head2 ret

   $ret = $method->ret

Returns the return type as a L<Tangence::Meta::Type> reference or C<undef> if
the method does not return a value.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

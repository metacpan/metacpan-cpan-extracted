#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::Meta::Argument 0.32;
class Tangence::Meta::Argument :strict(params);

=head1 NAME

C<Tangence::Meta::Argument> - structure representing one C<Tangence> method or event argument

=head1 DESCRIPTION

This data structure object stores information about one argument to a
L<Tangence> class method or event. Once constructed, such objects are
immutable.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $argument = Tangence::Meta::Argument->new( %args )

Returns a new instance initialised by the given arguments.

=over 8

=item name => STRING

Name of the argument

=item type => STRING

Type of the arugment as a L<Tangence::Meta::Type> reference

=back

=cut

field $name :reader :param = undef;
field $type :reader :param;

=head1 ACCESSORS

=cut

=head2 name

   $name = $argument->name

Returns the name of the class

=cut

=head2 type

   $type = $argument->type

Return the type as a L<Tangence::Meta::Type> reference.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

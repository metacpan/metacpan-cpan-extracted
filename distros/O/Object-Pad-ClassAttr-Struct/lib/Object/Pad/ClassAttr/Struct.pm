#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

package Object::Pad::ClassAttr::Struct 0.05;

use v5.14;
use warnings;

use Carp;

use Object::Pad 0.76 ':experimental(mop)';

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::ClassAttr::Struct> - declare an C<Object::Pad> class to be struct-like

=head1 SYNOPSIS

   use Object::Pad;
   use Object::Pad::ClassAttr::Struct;

   class Colour :Struct {
      # These get :param :mutator automatically
      has $red   = 0;
      has $green = 0;
      has $blue  = 0;

      # Additional methods are still permitted
      method lightness {
         return ($red + $green + $blue) / 3;
      }
   }

   my $cyan = Colour->new( green => 1, blue => 1 );

   # A positional constructor is created automatically
   my $white = Colour->new_values(1, 1, 1);

=head1 DESCRIPTION

This module provides a third-party class attribute for L<Object::Pad>-based
classes, which applies some attributes automatically to every field added to
the class, as a convenient shortcut for making structure-like classes.

=head1 CLASS ATTRIBUTES

=head2 :Struct

   class Name :Struct ... { ... }

Automatically applies the C<:param> and C<:mutator> attributes to every field
defined on the class, meaning the constructor will accept parameters for each
field to initialise the value, and each field will have an lvalue mutator
method.

In addition, the class itself gains the C<:strict(params)> attribute, meaning
the constructor will check parameter names and throw an exception for
unrecognised names.

I<Since version 0.04> a positional constructor class method called
C<new_values> is also provided into the class, which takes a value for every
field positionally, in declared order.

   $obj = ClassName->new_values($v1, $v2, $v3, ...);

This positional constructor must receive as many positional arguments as there
are fields in total in the class; even the optional ones. All arguments are
required here.

I<Since version 0.05> the following options are permitted inside the attribute
value parentheses:

=head3 :Struct(readonly)

Instances of this class do not permit fields to be modified after
construction. The accessor is created using the C<:reader> field attribute
rather than C<:mutator>.

=cut

sub import
{
   $^H{"Object::Pad::ClassAttr::Struct/Struct"}++;
}

sub _post_seal
{
   my ( $class ) = @_;
   my $classmeta = Object::Pad::MOP::Class->for_class( $class );

   # Select just the barename of each scalar field
   my @fieldnames = map { $_->name =~ m/^[\$](.*)$/ ? $1 : () } $classmeta->fields;
   # Put them back on again
   my $varnames   = join ", ", map { "\$$_" } @fieldnames;

   no strict 'refs';
   *{"${class}::new_values"} = sub {
      my $class = shift;
      @_ == @fieldnames or
         croak "Usage: $class\->new_values($varnames)";
      my %args;
      @args{@fieldnames} = @_;
      return $class->new( %args );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

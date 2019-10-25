#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Object::Pad;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

# So that feature->import will work in `class`
require feature;
if( $] >= 5.020 ) {
   require experimental;
   require indirect;
}

=head1 NAME

C<Object::Pad> - a simple syntax for lexical slot-based objects

=head1 SYNOPSIS

   use Object::Pad;

   class Point {
      has $x = 0;
      has $y = 0;

      method move($dX, $dY) {
         $x += $dX;
         $y += $dY;
      }

      method describe {
         print "A point at ($x, $y)\n";
      }
   }

=head1 DESCRIPTION

B<WARNING> This is a highly experimental proof-of-concept. Please don't
actually use this in production :)

This module provides a simple syntax for creating object classes, which uses
private variables that look like lexicals as object member fields.

=head1 KEYWORDS

=head2 class

   class Name {
      ...
   }

Behaves similarly to the C<package> keyword, but provides a package that
defines a new class. Such a class provides an automatic constructor method
called C<new>, which will invoke the class's C<BUILDALL> method if it exists.

A single superclass is supported by the keyword C<extends>

   class Cat extends Animal {
      ...
   }

The superclass must also be implemented by C<Object::Pad>.

=head2 has

   has $var;
   has $var = CONST;
   has @var;
   has %var;

Declares that the instances of the class have a member field of the given
name. This member field (called a "slot") will be accessible as a lexical
variable within any C<method> declarations in the class.

Array and hash members are permitted and behave as expected; you do not need
to store references to anonymous arrays or hashes.

Member fields are private to a class. They are not visible to users of the
class, nor to subclasses. In order to provide access to them a class may wish
to use L</method> to create an accessor.

A scalar slot may provide a expression that gives an initialisation value,
which will be assigned into the slot of every instance during the constructor
before C<BUILDALL> is invoked. For ease-of-implementation reasons this
expression must currently be a compiletime constant, but it is hoped that a
future version will relax this restriction and allow runtime-computed values.

=head2 method

   method NAME {
      ...
   }

   method NAME (SIGNATURE) {
      ...
   }

   method NAME :attrs... {
      ...
   }

Declares a new named method. This behaves similarly to the C<sub> keyword,
except that within the body of the method all of the member fields ("slots")
are also accessible. In addition, the method body will have a lexical called
C<$self> which contains the invocant object directly; it will already have
been shifted from the C<@_> array.

The C<signatures> feature is automatically enabled for method declarations. In
this case the signature does not have to account for the invocant instance; 
that is handled directly.

   method m($one, $two) {
      say "$self invokes method on one=$one two=$two";
   }

   ...
   $obj->m(1, 2);

A list of attributes may be supplied as for C<sub>. The most useful of these
is C<:lvalue>, allowing easy creation of read-write accessors for slots.

   class Counter {
      has $count;

      method count :lvalue { $count }
   }

   my $c = Counter->new;
   $c->count++;

=head1 IMPLIED PRAGMATA

In order to encourage users to write clean, modern code, the body of the
C<class> block acts as if the following pragmata are in effect:

   use strict;
   use warnings;
   no indirect ':fatal';
   use feature 'signatures';

This list may be extended in subsequent versions to add further restrictions
and should not be considered exhaustive.

Further additions will only be ones that remove "discouraged" or deprecated
language features with the overall goal of enforcing a more clean modern style
within the body. As long as you write code that is in a clean, modern style
(and I fully accept that this wording is vague and subjective) you should not
find any new restrictions to be majorly problematic. Either the code will
continue to run unaffected, or you may have to make some small alterations to
bring it into a conforming style.

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my ( $caller, @syms ) = @_;

   @syms or @syms = qw( class method has );

   my %syms = map { $_ => 1 } @syms;
   delete $syms{$_} and $^H{"Object::Pad/$_"}++ for qw( class method has );

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

sub Object::Pad::_base::new
{
   my $class = shift;

   my $self = bless [], $class;
   $self->INITSLOTS;

   $self->BUILDALL( @_ ) if $self->can( "BUILDALL" );

   return $self;
}

=head1 TODO

=over 4

=item *

Setting default package using C<class Name;> statement without block.

=item *

Multiple inheritence of subclassing

=item *

Roles

=item *

Consider visibility of superclass slots to subclasses.

=item *

Experiment with C<CvOUTSIDE> or other techniques as a way to set up the
per-method pad, and consider if we can detect which slots are in use that way
to improve method-enter performance.

=item *

Some extensions of the C<has> syntax:

Non-constant default expressions

   has $var = EXPR;

A way to request generated accessors - ro or rw.

=item *

Work out why C<no indirect> doesn't appear to work properly before perl 5.20.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

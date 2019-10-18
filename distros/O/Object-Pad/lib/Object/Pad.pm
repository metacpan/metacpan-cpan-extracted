#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Object::Pad;

use strict;
use warnings;

our $VERSION = '0.02';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Object::Pad> - a simple syntax for lexical slot-based objects

=head1 SYNOPSIS

   use Object::Pad;

   class Point {
      has $x;
      has $y;

      method CREATE {
         $x = $y = 0;
      }

      method move {
         $x += shift;
         $y += shift;
      }

      method describe {
         print "A point at ($x, $y)\n";
      }
   }

=head1 DESCRIPTION

B<WARNING> This is a highly experimental proof-of-concept. Please don't
actually use this in production :)

This module provides a simple syntax for creating object classes, which uses
private variables that look like lexicals as object member attributes.

=head1 KEYWORDS

=head2 class

   class Name {
      ...
   }

Behaves similarly to the C<package> keyword, but provides a package that
defines a new class. Such a class provides an automatic constructor method
called C<new>, which will invoke the class's C<CREATE> method if it exists.

=head2 has

   has $var;
   has @var;
   has %var;

Declares that the instances of the class have a member attribute of the given
name. This member attribute (called a "slot") will be accessible as a lexical
variable within any C<method> declarations in the class.

Array and hash members are permitted and behave as expected; you do not need
to store references to anonymous arrays or hashes.

=head2 method

   method NAME {
      ...
   }

   method NAME :attrs... {
      ...
   }

Declares a new named method. This behaves similarly to the C<sub> keyword,
except that within the body of the method all of the member attributes
("slots") are also accessible. In addition, the method body will have a
lexical called C<$self> which contains the invocant object directly; it will
already have been shifted from the C<@_> array.

A list of attributes may be supplied as for C<sub>. The most useful of these
is C<:lvalue>, allowing easy creation of read-write accessors for slots.

   class Counter {
      has $count;

      method count :lvalue { $count }
   }

   my $c = Counter->new;
   $c->count++;

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

=head1 TODO

=over 4

=item *

Setting default package using C<class Name;> statement without block.

=item *

Subclassing. Single-inheritence is easier than multi so maybe that first.

=item *

Sub signatures

=item *

Detect and croak on attempts to invoke C<method> subs on non-instances.

=item *

Experiment with C<CvOUTSIDE> or other techniques as a way to set up the
per-method pad, and consider if we can detect which slots are in use that way
to improve method-enter performance.

=item *

Some extensions of the C<has> syntax:

Default expressions

   has $var = DEFAULT;

A way to request generated accessors - ro or rw.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

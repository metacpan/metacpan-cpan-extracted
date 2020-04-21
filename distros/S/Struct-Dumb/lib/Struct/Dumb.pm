#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2020 -- leonerd@leonerd.org.uk

package Struct::Dumb;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;

use Scalar::Util qw( refaddr );

# 'overloading.pm' was only added in 5.10
# Before that we can't easily implement forbidding of @{} overload, so lets not
use constant HAVE_OVERLOADING => eval { require overloading };

=head1 NAME

C<Struct::Dumb> - make simple lightweight record-like structures

=head1 SYNOPSIS

 use Struct::Dumb;

 struct Point => [qw( x y )];

 my $point = Point(10, 20);

 printf "Point is at (%d, %d)\n", $point->x, $point->y;

 $point->y = 30;
 printf "Point is now at (%d, %d)\n", $point->x, $point->y;

Z<>

 struct Point3D => [qw( x y z )], named_constructor => 1;

 my $point3d = Point3D( z => 12, x => 100, y => 50 );

 printf "Point3d's height is %d\n", $point3d->z;

Z<>

 struct Point3D => [qw( x y z )], predicate => "is_Point3D";

 my $point3d = Point3D( 1, 2, 3 );

 printf "This is a Point3D\n" if is_Point3D( $point3d );

Z<>

 use Struct::Dumb qw( -named_constructors )

 struct Point3D => [qw( x y z )];

 my $point3d = Point3D( x => 100, z => 12, y => 50 );

=head1 DESCRIPTION

C<Struct::Dumb> creates record-like structure types, similar to the C<struct>
keyword in C, C++ or C#, or C<Record> in Pascal. An invocation of this module
will create a construction function which returns new object references with
the given field values. These references all respond to lvalue methods that
access or modify the values stored.

It's specifically and intentionally not meant to be an object class. You
cannot subclass it. You cannot provide additional methods. You cannot apply
roles or mixins or metaclasses or traits or antlers or whatever else is in
fashion this week.

On the other hand, it is tiny, creates cheap lightweight array-backed
structures, uses nothing outside of core. It's intended simply to be a
slightly nicer way to store data structures, where otherwise you might be
tempted to abuse a hash, complete with the risk of typoing key names. The
constructor will C<croak> if passed the wrong number of arguments, as will
attempts to refer to fields that don't exist. Accessor-mutators will C<croak>
if invoked with arguments. (This helps detect likely bugs such as accidentally
passing in the new value as an argument, or attempting to invoke a stored
C<CODE> reference by passing argument values directly to the accessor.)

 $ perl -E 'use Struct::Dumb; struct Point => [qw( x y )]; Point(30)'
 usage: main::Point($x, $y) at -e line 1

 $ perl -E 'use Struct::Dumb; struct Point => [qw( x y )]; Point(10,20)->z'
 main::Point does not have a 'z' field at -e line 1

 $ perl -E 'use Struct::Dumb; struct Point => [qw( x y )]; Point(1,2)->x(3)'
 main::Point->x invoked with arguments at -e line 1.

Objects in this class are (currently) backed by an ARRAY reference store,
though this is an internal implementation detail and should not be relied on
by using code. Attempting to dereference the object as an ARRAY will throw an
exception.

=head2 CONSTRUCTOR FORMS

The C<struct> and C<readonly_struct> declarations create two different kinds
of constructor function, depending on the setting of the C<named_constructor>
option. When false, the constructor takes positional values in the same order
as the fields were declared. When true, the constructor takes a key/value pair
list in no particular order, giving the value of each named field.

This option can be specified to the C<struct> and C<readonly_struct>
functions. It defaults to false, but it can be set on a per-package basis to
default true by supplying the C<-named_constructors> option on the C<use>
statement.

When using named constructors, individual fields may be declared as being
optional. By preceeding the field name with a C<?> character, the constructor
is instructed not to complain if a named parameter is not given for that
field; instead it will be set to C<undef>.

   struct Person => [qw( name age ?address )],
      named_constructor => 1;

   my $bob = Person( name => "Bob", age => 20 );
   # This is valid because 'address' is marked as optional

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   my %default_opts;
   my %syms;

   foreach ( @_ ) {
      if( $_ eq "-named_constructors" ) {
         $default_opts{named_constructor} = 1;
      }
      else {
         $syms{$_}++;
      }
   }

   keys %syms or $syms{struct}++;

   my %export;

   if( delete $syms{struct} ) {
      $export{struct} = sub {
         my ( $name, $fields, @opts ) = @_;
         _struct( $name, $fields, scalar caller, lvalue => 1, %default_opts, @opts );
      };
   }
   if( delete $syms{readonly_struct} ) {
      $export{readonly_struct} = sub {
         my ( $name, $fields, @opts ) = @_;
         _struct( $name, $fields, scalar caller, lvalue => 0, %default_opts, @opts );
      };
   }

   if( keys %syms ) {
      croak "Unrecognised export symbols " . join( ", ", keys %syms );
   }

   no strict 'refs';
   *{"${caller}::$_"} = $export{$_} for keys %export;
}

=head1 FUNCTIONS

=cut

my %_STRUCT_PACKAGES;

sub _struct
{
   my ( $name, $_fields, $caller, %opts ) = @_;

   my $lvalue = !!$opts{lvalue};
   my $named  = !!$opts{named_constructor};

   my $pkg = "${caller}::$name";

   my @fields = @$_fields;

   my %optional;
   s/^\?// and $optional{$_}++ for @fields;

   my $constructor;
   if( $named ) {
      $constructor = sub {
         my %values = @_;
         my @values;
         foreach ( @fields ) {
            exists $values{$_} or $optional{$_} or
               croak "usage: $pkg requires '$_'";
            push @values, delete $values{$_};
         }
         if( my ( $extrakey ) = keys %values ) {
            croak "usage: $pkg does not recognise '$extrakey'";
         }
         bless \@values, $pkg;
      };
   }
   else {
      my $fieldcount = @fields;
      my $argnames = join ", ", map "\$$_", @fields;
      $constructor = sub {
         @_ == $fieldcount or croak "usage: $pkg($argnames)";
         bless [ @_ ], $pkg;
      };
   }

   my %subs;
   foreach ( 0 .. $#fields ) {
      my $idx = $_;
      my $field = $fields[$idx];

      BEGIN {
         overloading->unimport if HAVE_OVERLOADING;
      }

      $subs{$field} = $lvalue
         ? sub :lvalue { @_ > 1 and croak "$pkg->$field invoked with arguments";
                         shift->[$idx] }
         : sub         { @_ > 1 and croak "$pkg->$field invoked with arguments";
                         shift->[$idx] };
   }
   $subs{DESTROY} = sub {};
   $subs{AUTOLOAD} = sub :lvalue {
      my ( $field ) = our $AUTOLOAD =~ m/::([^:]+)$/;
      croak "$pkg does not have a '$field' field";
      my $dummy; ## croak can't be last because it isn't lvalue, so this line is required
   };

   no strict 'refs';
   *{"${pkg}::$_"} = $subs{$_} for keys %subs;
   *{"${caller}::$name"} = $constructor;

   if( my $predicate = $opts{predicate} ) {
      *{"${caller}::$predicate"} = sub { ( ref($_[0]) || "" ) eq $pkg };
   }

   *{"${pkg}::_forbid_arrayification"} = sub {
      return if !HAVE_OVERLOADING and caller eq __PACKAGE__;
      croak "Cannot use $pkg as an ARRAY reference"
   };

   require overload;
   $pkg->overload::OVERLOAD(
      '@{}'  => sub { $_[0]->_forbid_arrayification; return $_[0] },
      '0+'   => sub { refaddr $_[0] },
      '""'   => sub { sprintf "%s=Struct::Dumb(%#x)", $pkg, refaddr $_[0] },
      'bool' => sub { 1 },
      fallback => 1,
   );

   $_STRUCT_PACKAGES{$pkg} = {
      named  => $named,
      fields => \@fields,
   }
}

=head2 struct

   struct $name => [ @fieldnames ],
      named_constructor => (1|0),
      predicate         => "is_$name";

Creates a new structure type. This exports a new function of the type's name
into the caller's namespace. Invoking this function returns a new instance of
a type that implements those field names, as accessors and mutators for the
fields.

Takes the following options:

=over 4

=item named_constructor => BOOL

Determines whether the structure will take positional or named arguments.

=item predicate => STR

If defined, gives the name of a second function to export to the caller's
namespace. This function will be a type test predicate; that is, a function
that takes a single argmuent, and returns true if-and-only-if that argument is
an instance of this structure type.

=back

=cut

=head2 readonly_struct

   readonly_struct $name => [ @fieldnames ],
      ...

Similar to L</struct>, but instances of this type are immutable once
constructed. The field accessor methods will not be marked with the
C<:lvalue> attribute.

Takes the same options as L</struct>.

=cut

=head1 DATA::DUMP FILTER

I<Since version 0.10.>

If L<Data::Dump> is loaded, an extra filter is applied so that struct
instances are printed in a format matching that which would construct them.

   struct Colour => [qw( red green blue )];

   use Data::Dump;

   my %hash = ( col => Colour( 0.8, 0.5, 0.2 ) );
   Data::Dump::dd \%hash;

   # prints {col => main::Colour(0.8, 0.5, 0.2)}

=head1 NOTES

=head2 Allowing ARRAY dereference

The way that forbidding access to instances as if they were ARRAY references
is currently implemented uses an internal method on the generated structure
class called C<_forbid_arrayification>. If special circumstances require that
this exception mechanism be bypassed, the method can be overloaded with an
empty C<sub {}> body, allowing the struct instances in that class to be
accessed like normal ARRAY references. For good practice this should be
limited by a C<local> override.

For example, L<Devel::Cycle> needs to access the instances as plain ARRAY
references so it can walk the data structure looking for reference cycles.

 use Devel::Cycle;

 {
    no warnings 'redefine';
    local *Point::_forbid_arrayification = sub {};

    memory_cycle_ok( $point );
 }

=head1 TODO

=over 4

=item *

Consider adding an C<coerce_hash> option, giving name of another function to
convert structs to key/value pairs, or a HASH ref.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

sub maybe_apply_datadump_filter
{
   return unless $INC{"Data/Dump.pm"};

   require Data::Dump::Filtered;

   Data::Dump::Filtered::add_dump_filter( sub {
      my ( $ctx, $obj ) = @_;
      return undef unless my $meta = $_STRUCT_PACKAGES{ $ctx->class };

      BEGIN {
         overloading->unimport if HAVE_OVERLOADING;
      }

      my $fields = $meta->{fields};
      return {
         dump => sprintf "%s(%s)", $ctx->class,
            join ", ", map {
               ( $meta->{named} ? "$fields->[$_] => " : "" ) .
               Data::Dump::dump($obj->[$_])
            } 0 .. $#$fields
      };
   });
}

if( defined &Data::Dump::dump ) {
   maybe_apply_datadump_filter;
}
else {
   # A package var we observe that Data/Dump.pm seems to set when loaded
   # We can't attach to VERSION because too many other things get upset by
   # that.
   $Data::Dump::DEBUG = bless \( my $x = \&maybe_apply_datadump_filter ),
      "Struct::Dumb::_DestroyWatch";
}

{
   package Struct::Dumb::_DestroyWatch;
   my $GD = 0;
   END { $GD = 1 }
   sub DESTROY { ${$_[0]}->() unless $GD; }
}

0x55AA;

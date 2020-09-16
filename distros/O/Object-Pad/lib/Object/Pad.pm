#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2020 -- leonerd@leonerd.org.uk

package Object::Pad;

use v5.14;
use warnings;

our $VERSION = '0.33';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

# So that feature->import will work in `class`
require feature;
if( $] >= 5.020 ) {
   require experimental;
   require indirect if $] < 5.031009;
}

require mro;

=head1 NAME

C<Object::Pad> - a simple syntax for lexical slot-based objects

=head1 SYNOPSIS

   use Object::Pad;

   class Point {
      has $x = 0;
      has $y = 0;

      BUILD {
        ($x, $y) = @_;
      }

      method move ($dX, $dY) {
         $x += $dX;
         $y += $dY;
      }

      method describe {
         print "A point at ($x, $y)\n";
      }
   }

   Point->new(5,10)->describe;

=head1 DESCRIPTION

B<WARNING> This is an experimental proof-of-concept. Please don't actually
use this in production unless you are crazy :)

This module provides a simple syntax for creating object classes, which uses
private variables that look like lexicals as object member fields.

=head2 Automatic Construction

Classes are automatically provided with a constructor method, called C<new>,
which helps create the object instances.

As part of the construction process, the C<BUILD> block of every component
class will be invoked, passing in the list of arguments the constructor was
invoked with. Each class should perform its required setup behaviour, but does
not need to chain to the C<SUPER> class first; this is handled automatically.

If the class provides a C<BUILDARGS> class method, that is used to mangle the
list of arguments before the C<BUILD> blocks are called. Note this must be a
class method not an instance method (and so implemented using C<sub>). It
should perform any C<SUPER> chaining as may be required.

   @args = $class->BUILDARGS( @_ )

=head1 KEYWORDS

=head2 class

   class Name :ATTRS... {
      ...
   }

   class Name :ATTRS...;

Behaves similarly to the C<package> keyword, but provides a package that
defines a new class. Such a class provides an automatic constructor method
called C<new>.

As with C<package>, an optional block may be provided. If so, the contents of
that block define the new class and the preceding package continues
afterwards. If not, it sets the class as the package context of following
keywords and definitions.

As with C<package>, an optional version declaration may be given. If so, this
sets the value of the package's C<$VERSION> variable.

   class Name VERSION { ... }

   class Name VERSION;

A single superclass is supported by the keyword C<extends>

   class Name extends BASECLASS {
      ...
   }

   class Name extends BASECLASS BASEVER {
      ...
   }

If a package providing the superclass does not exist, an attempt is made to
load it by code equivalent to

   require Animal ();

and thus it must either already exist, or be locatable via the usual C<@INC>
mechanisms.

The superclass may or may not itself be implemented by C<Object::Pad>, but if
it is not then see L<SUBCLASSING CLASSIC PERL CLASSES> for further detail on
the semantics of how this operates.

An optional version check can also be supplied; it performs the equivalent of

   BaseClass->VERSION( $ver )

An optional list of attributes may be supplied in similar syntax as for subs
or lexical variables. (These are annotations about the class itself; the
concept should not be confused with per-object-instance data, which here is
called "slots").

One or more roles can be composed into the class by the keyword C<implements>

   class Name implements ROLE, ROLE,... {
      ...
   }

The following class attributes are supported:

=head3 :repr(TYPE)

Sets the representation type for instances of this class. Must be one of the
following values:

   :repr(native)

The native representation. This is an opaque representation type whose
contents are not specified. It only works for classes whose entire inheritence
hierarchy is built only from classes based on C<Object::Pad>.

   :repr(HASH)

The representation will be a blessed hash reference. The instance data will
be stored in an array referenced by a key called C<Object::Pad/slots>, which
is fairly unlikely to clash with existing storage on the instance. No other
keys will be used; they are available for implementions and subclasses to use.
The exact format of the value stored here is not specified and may change
between module versions, though it can be relied on to be well-behaved as some
kind of perl data structure for purposes of modules like L<Data::Dumper> or
serialisation into things like C<YAML> or C<JSON>.

This representation type may be useful when converting existing classes into
using C<Object::Pad> where there may be existing subclasses of it that presume
a blessed hash for their own use.

   :repr(magic)

The representation will use MAGIC to apply the instance data in a way that is
invisible at the Perl level, and shouldn't get in the way of other things the
instance is doing even in XS modules.

This representation type is the only one that will work for subclassing
existing classes that do not use blessed hashes.

   :repr(autoselect), :repr(default)

I<Since version 0.23.>

This representation will select one of the representations above depending on
what is best for the situation. Classes not derived from a non-C<Object::Pad>
base class will pick C<native>, and classes derived from non-C<Object::Pad>
bases will pick either the C<HASH> or C<magic> forms depending on whether the
instance is a blessed hash reference or some other kind.

This achieves the best combination of DWIM while still allowing the common
forms of hash reference to be inspected by C<Data::Dumper>, etc. This is the
default representation type, and does not have to be specifically requested.

=head2 role

   role Name :ATTRS... {
      ...
   }

   role Name :ATTRS...;

I<Since version 0.32.>

Similar to C<class>, but provides a package that defines a new role. A role
acts simliar to a class in some respects, and differently in others.

Like a class, a role can have a version, and named methods.

   role Name VERSION {
      method a { ... }
      method b { ... }
   }

A role does not provide a constructor, and instances cannot directly be
constructed. A role cannot extend a class.

A role can declare that it requires methods of given names from any class that
implements the role.

   role Name {
      requires METHOD;
   }

A role can provide instance slots. These are visible to any C<BUILD> blocks or
methods provided by that role.

I<Since version 0.33.>

   role Name {
      has $slot;

      BUILD { $slot = "a value" }

      method slot { return $slot }
   }

=head2 has

   has $var;
   has $var = EXPR;
   has @var;
   has %var;

   has $var :ATTR ATTR...;

Declares that the instances of the class or role have a member field of the
given name. This member field (called a "slot") will be accessible as a
lexical variable within any C<method> declarations in the class.

Array and hash members are permitted and behave as expected; you do not need
to store references to anonymous arrays or hashes.

Member fields are private to a class or role. They are not visible to users of
the class, nor to subclasses, nor to any class that a role is applied to. In
order to provide access to them a class may wish to use L</method> to create
an accessor.

A scalar slot may provide a expression that gives an initialisation value,
which will be assigned into the slot of every instance during the constructor
before the C<BUILD> blocks are invoked. I<Since version 0.29> this expression
does not have to be a compiletime constant, though it is evaluated exactly
once, at runtime, after the class definition has been parsed. It is not
evaluated individually for every object instance of that class.

The following slot attributes are supported:

=head3 :reader, :reader(NAME)

I<Since version 0.27.>

Generates a reader method to return the current value of the slot. Currently
these are only permitted for scalar slots. If no name is given, the name of
the slot is used. A single prefix character C<_> will be removed if present.

   has $slot :reader;

   # equivalent to
   has $slot;  method slot { return $slot }

=head3 :writer, :writer(NAME)

I<Since version 0.27.>

Generates a writer method to set a new value of the slot from its first
argument. Currently these are only permitted for scalar slots. If no name is
given, the name of the slot is used prefixed by C<set_>. A single prefix
character C<_> will be removed if present.

   has $slot :writer;

   # equivalent to
   has $slot;  method set_slot { $slot = shift; return $self }

I<Since version 0.28> a generated writer method will return the object
invocant itself, allowing a chaining style.

   $obj->set_x("x")
      ->set_y("y")
      ->set_z("z");

=head3 :mutator, :mutator(NAME)

I<Since version 0.27.>

Generates an lvalue mutator method to return or set the value of the slot.
These are only permitted for scalar slots. If no name is given, the name of
the slot is used. A single prefix character C<_> will be removed if present.

   has $slot :mutator;

   # equivalent to
   has $slot;  method slot :lvalue { $slot }

I<Since version 0.28> all of these generated accessor methods will include
argument checking similar to that used by subroutine signatures, to ensure the
correct number of arguments are passed - usually zero, but exactly one in the
case of a C<:writer> method.

=head2 method

   method NAME {
      ...
   }

   method NAME (SIGNATURE) {
      ...
   }

   method NAME :ATTRS... {
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

   method m ($one, $two) {
      say "$self invokes method on one=$one two=$two";
   }

   ...
   $obj->m(1, 2);

A list of attributes may be supplied as for C<sub>. The most useful of these
is C<:lvalue>, allowing easy creation of read-write accessors for slots (but
see also the C<:reader>, C<:writer> and C<:mutator> slot attributes).

   class Counter {
      has $count;

      method count :lvalue { $count }
   }

   my $c = Counter->new;
   $c->count++;

Every method automatically gets the C<:method> attribute applied, which
suppresses warnings about ambiguous calls resolved to core functions if the
name of a method matches a core function.

The following additional attributes are recognised by C<Object::Pad> directly:

=head3 :override

I<Since version 0.29.>

Marks that this method expects to override another of the same name from a
superclass. It is an error at compiletime if the superclass does not provide
such a method.

=head2 BUILD

   BUILD {
      ...
   }

   BUILD (SIGNATURE) {
      ...
   }

I<Since version 0.27.>

Declares the builder block for this component class. A builder block may use
subroutine signature syntax, as for methods, to assist in unpacking its
arguments. A build block is not a subroutine and thus is not permitted to use
subroutine attributes (for example C<:lvalue>).

Currently attempts to create a method named C<BUILD> (i.e. with syntax
C<method BUILD {...}>) will create a builder block instead. As of version 0.31
such attempts will print a warning at compiletime, and a later version may
remove this altogether.

=head2 requires

   requires NAME;

Declares that this role requires a method of the given name from any class
that implements it. It is an error at compiletime if the implementing class
does not provide such a method.

=head1 IMPLIED PRAGMATA

In order to encourage users to write clean, modern code, the body of the
C<class> block acts as if the following pragmata are in effect:

   use strict;
   use warnings;
   no indirect ':fatal';  # or  no feature 'indirect' on perl 5.32 onwards
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

=head1 SUBCLASSING CLASSIC PERL CLASSES

There are a number of details specific to the case of deriving an
C<Object::Pad> class from an existing classic Perl class that is not
implemented using C<Object::Pad>.

=head2 Storage of Instance Data

Instances will pick either the C<:repr(HASH)> or C<:repr(magic)> storage type.

=head2 Object State During Methods Invoked By Superclass Constructor

It is common in classic Perl OO style to invoke methods on C<$self> during
the constructor. This is supported here since C<Object::Pad> version 0.19.
Note however that any methods invoked by the superclass constructor may not
see the object in a fully consistent state. (This fact is not specific to
using C<Object::Pad> and would happen in classic Perl OO as well). The slot
initialisers will have been invoked but the C<BUILD> blocks will not.

For example; in the following

   package ClassicPerlBaseClass {
      sub new {
         my $self = bless {}, shift;
         say "Value seen by superconstructor is ", $self->get_value;
         return $self;
      }
      sub get_value { return "A" }
   }

   class DerivedClass extends ClassicPerlBaseClass {
      has $_value = "B";
      BUILD {
         $_value = "C";
      }
      method get_value { return $_value }
   }

   my $obj = DerivedClass->new;
   say "Value seen by user is ", $obj->get_value;

Until the C<ClassicPerlBaseClass::new> superconstructor has returned the
C<BUILD> block will not have been invoked. The C<$_value> slot will still
exist, but its value will be C<B> during the superconstructor. After the
superconstructor, the C<BUILD> blocks are invoked before the completed object
is returned to the user. The result will therefore be:

   Value seen by superconstructor is B
   Value seen by user is C

=head1 STYLE SUGGESTIONS

While in no way required, the following suggestions of code style should be
noted in order to establish a set of best practices, and encourage consistency
of code which uses this module.

=head2 $VERSION declaration

While it would be nice for CPAN and other toolchain modules to parse the
embedded version declarations in C<class> statements, the current state at
time of writing (June 2020) is that none of them actually do. As such, it will
still be necessary to make a once-per-file C<$VERSION> declaration in syntax
those modules can parse.

Further note that these modules will also not parse the C<class> declaration,
so you will have to duplicate this with a C<package> declaration as well as a
C<class> keyword. This does involve repeating the package name, so is slightly
undesirable.

It is hoped that eventually upstream toolchain modules will be adapted to
accept the C<class> syntax as being sufficient to declare a package and set
its version.

See also

=over 2

=item *

L<https://github.com/Perl-Toolchain-Gang/Module-Metadata/issues/33>

=back

=head2 File Layout

Begin the file with a C<use Object::Pad> line; ideally including a
minimum-required version. This should be followed by the toplevel C<package>
and C<class> declarations for the file. As it is at toplevel there is no need
to use the block notation; it can be a unit class.

There is no need to C<use strict> or apply other usual pragmata; these will
be implied by the C<class> keyword.

   use Object::Pad 0.16;

   package My::Classname 1.23;
   class My::Classname;

   # other use statements

   # has, methods, etc.. can go here

=head2 Slot Names

Slot names should follow similar rules to regular lexical variables in code -
lowercase, name components separated by underscores. For tiny examples such as
"dumb record" structures this may be sufficient.

   class Tag {
      has $name  :mutator;
      has $value :mutator;
   }

In larger examples with lots of non-trivial method bodies, it can get
confusing to remember where the slot variables come from (because we no longer
have the C<< $self->{ ... } >> visual clue). In these cases it is suggested to
prefix the slot names with a leading underscore, to make them more visually
distinct.

   class Spudger {
      has $_grapefruit;

      ...

      method mangle {
         $_grapefruit->peel; # The leading underscore reminds us this is a slot
      }
   }

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

   @syms or @syms = qw( class role method has requires );

   my %syms = map { $_ => 1 } @syms;
   delete $syms{$_} and $^H{"Object::Pad/$_"}++ for qw( class role method has requires );

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

# Double-experimental MOP-like API
# Currently entirely undocumented. May eventually become part of an Object::Pad::MOP API
sub begin_class
{
   my $class = shift;
   my ( $name, %args ) = @_;

   Object::Pad::_begin_class( $name, $args{extends} );
}

# The universal base-class methods

sub Object::Pad::UNIVERSAL::BUILDARGS
{
   shift; # $class
   return @_;
}

=head1 WITH OTHER MODULES

=head2 Syntax::Keyword::Dynamically

A cross-module integration test asserts that C<dynamically> works correctly
on object instance slots:

   use Object::Pad;
   use Syntax::Keyword::Dynamically;

   class Container {
      has $value = 1;

      method example {
         dynamically $value = 2;
         ,..
         # value is restored to 1 on return from this method
      }
   }

=head2 Future::AsyncAwait

As of L<Future::AsyncAwait> version 0.38 and L<Object::Pad> version 0.15, both
modules now use L<XS::Parse::Sublike> to parse blocks of code. Because of this
the two modules can operate together and allow class methods to be written as
async subs which await expressions:

   use Future::AsyncAwait;
   use Object::Pad;

   class Example
   {
      async method perform ($block)
      {
         say "$self is performing code";
         await $block->();
         say "code finished";
      }
   }

These three modules combine; there is additionally a cross-module test to
ensure that object instance slots can be C<dynamically> set during a suspended
C<async method>.

=head1 DESIGN TODOs

The following points are details about the design of pad slot-based object
systems in general:

=over 4

=item *

Is multiple inheritence actually required, if role composition is implemented
including giving roles the ability to use private slots?

=item *

Consider the visibility of superclass slots to subclasses. Do subclasses even
need to be able to see their superclass's slots, or are accessor methods
always appropriate?

Concrete example: The C<< $self->{split_at} >> access that
L<Tickit::Widget::HSplit> makes of its parent class
L<Tickit::Widget::LinearSplit>.

=back

=head1 IMPLEMENTATION TODOs

These points are more about this particular module's implementation:

=over 4

=item *

Implement roles, including required method checking and the ability to have
private slots.

=item *

Consider multiple inheritence of subclassing, if that is still considered
useful after adding roles.

=item *

Work out why C<no indirect> doesn't appear to work properly before perl 5.20.

=item *

Work out why we don't get a C<Subroutine new redefined at ...> warning if we

  sub new { ... }

=item *

The C<local> modifier does not work on slot variables, because they appear to
be regular lexicals to the parser at that point. A workaround is to use
L<Syntax::Keyword::Dynamically> instead:

   use Syntax::Keyword::Dynamically;

   has $loglevel;

   method quietly {
      dynamically $loglevel = LOG_ERROR;
      ...
   }

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

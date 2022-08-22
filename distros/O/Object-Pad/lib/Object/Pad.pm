#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2022 -- leonerd@leonerd.org.uk

package Object::Pad 0.68;

use v5.14;
use warnings;

use Carp;

sub dl_load_flags { 0x01 }

require DynaLoader;
__PACKAGE__->DynaLoader::bootstrap( our $VERSION );

our $XSAPI_VERSION = "0.48";

# So that feature->import will work in `class`
require feature;
if( $] >= 5.020 ) {
   require experimental;
   require indirect if $] < 5.031009;
}

require mro;

require Object::Pad::MOP::Class;

=encoding UTF-8

=head1 NAME

C<Object::Pad> - a simple syntax for lexical field-based objects

=head1 SYNOPSIS

On perl version 5.26 onwards:

   use v5.26;
   use Object::Pad;

   class Point {
      has $x :param = 0;
      has $y :param = 0;

      method move ($dX, $dY) {
         $x += $dX;
         $y += $dY;
      }

      method describe () {
         print "A point at ($x, $y)\n";
      }
   }

   Point->new(x => 5, y => 10)->describe;

Or, for older perls that lack signatures:

   use Object::Pad;

   class Point {
      has $x :param = 0;
      has $y :param = 0;

      method move {
         my ($dX, $dY) = @_;
         $x += $dX;
         $y += $dY;
      }

      method describe {
         print "A point at ($x, $y)\n";
      }
   }

   Point->new(x => 5, y => 10)->describe;

=head1 DESCRIPTION

This module provides a simple syntax for creating object classes, which uses
private variables that look like lexicals as object member fields.

While most of this module has evolved into a stable state in practice, parts
remain B<experimental> because the design is still evolving, and many features
and ideas have yet to implemented. I don't yet guarantee I won't have to
change existing details in order to continue its development. Feel free to try
it out in experimental or newly-developed code, but don't complain if a later
version is incompatible with your current code and you'll have to change it.

That all said, please do get in contact if you find the module overall useful.
The more feedback you provide in terms of what features you are using, what
you find works, and what doesn't, will help the ongoing development and
hopefully eventual stability of the design. See the L</FEEDBACK> section.

=head2 Experimental Features

I<Since version 0.63.>

Some of the features of this module are currently marked as experimental. They
will provoke warnings in the C<experimental> category, unless silenced.

You can silence this with C<no warnings 'experimental'> but then that will
silence every experimental warning, which may hide others unintentionally. For
a more fine-grained approach you can instead use the import line for this
module to only silence the module's warnings selectively:

   use Object::Pad ':experimental(init_expr)';

   use Object::Pad ':experimental(mop)';

   use Object::Pad ':experimental(custom_field_attr)';

   use Object::Pad ':experimental';  # all of the above

I<Since version 0.64.>

Multiple experimental features can be enabled at once by giving multiple names
in the parens, separated by spaces:

   use Object::Pad ':experimental(init_expr mop)';

=head2 Automatic Construction

Classes are automatically provided with a constructor method, called C<new>,
which helps create the object instances. This may respond to passed arguments,
automatically assigning values of fields, and invoking other blocks of code
provided by the class. It proceeds in the following stages:

=head3 The BUILDARGS phase

If the class provides a C<BUILDARGS> class method, that is used to mangle the
list of arguments before the C<BUILD> blocks are called. Note this must be a
class method not an instance method (and so implemented using C<sub>). It
should perform any C<SUPER> chaining as may be required.

   @args = $class->BUILDARGS( @_ )

=head3 Field assignment

If any field in the class has the C<:param> attribute, then the constructor
will expect to receive its argmuents in an even-sized list of name/value
pairs. This applies even to fields inherited from the parent class or applied
roles. It is therefore a good idea to shape the parameters to the constructor
in this way in roles, and in classes if you intend your class to be extended.

The constructor will also check for required parameters (these are all the
parameters for fields that do not have default initialisation expressions). If
any of these are missing an exception is thrown.

=head3 The BUILD phase

As part of the construction process, the C<BUILD> block of every component
class will be invoked, passing in the list of arguments the constructor was
invoked with. Each class should perform its required setup behaviour, but does
not need to chain to the C<SUPER> class first; this is handled automatically.

=head3 The ADJUST phase

Next, the C<ADJUST> block of every component class is invoked. This happens
after the fields are assigned their initial values and the C<BUILD> blocks
have been run.

=head3 The strict-checking phase

Finally, before the object is returned, if the L</:strict(params)> class
attribute is present, then the constructor will throw an exception if there
are any remaining named arguments left over after assigning them to fields as
per C<:param> declarations, and running any C<ADJUST> blocks.

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

A single superclass is supported by the keyword C<isa>

I<Since version 0.41.>

   class Name isa BASECLASS {
      ...
   }

   class Name isa BASECLASS BASEVER {
      ...
   }

Prior to version 0.41 this was called C<extends>, which is currently
recognised as a compatibility synonym. Both C<extends> and C<isa> keywords are
now deprecated, in favour of the L</:isa> attribute which is preferred
because it follows a more standard grammar without this special-case.

One or more roles can be composed into the class by the keyword C<does>

I<Since version 0.41.>

   class Name does ROLE, ROLE,... {
      ...
   }

Prior to version 0.41 this was called C<implements>, which is currently
recognised as a compatibility synonym. Both C<implements> and C<does> keywords
are now deprecated, in favour of the L</:does> attribute which is preferred
because it follows a more standard grammar without this special-case.

An optional list of attributes may be supplied in similar syntax as for subs
or lexical variables. (These are annotations about the class itself; the
concept should not be confused with per-object-instance data, which here is
called "fields").

Whitespace is permitted within the value and is automatically trimmed, but as
standard Perl parsing rules, no space is permitted between the attribute's
name and the open parenthesis of its value:

   :attr( value here )     # is permitted
   :attr (value here)      # not permitted

The following class attributes are supported:

=head3 :isa

   :isa(CLASS)

   :isa(CLASS CLASSVER)

I<Since version 0.57.>

Declares a superclass that this class extends. At most one superclass is
supported.

If the package providing the superclass does not exist, an attempt is made to
load it by code equivalent to

   require CLASS ();

and thus it must either already exist, or be locatable via the usual C<@INC>
mechanisms.

The superclass may or may not itself be implemented by C<Object::Pad>, but if
it is not then see L<SUBCLASSING CLASSIC PERL CLASSES> for further detail on
the semantics of how this operates.

An optional version check can also be supplied; it performs the equivalent of

   BaseClass->VERSION( $ver )

=head3 :does

   :does(ROLE)

   :does(ROLE ROLEVER)

I<Since version 0.57.>

Composes a role into the class; optionally requiring a version check on the
role package. This is a newer form of the C<implements> and C<does>
keywords and should be preferred for new code.

Multiple roles can be composed by using multiple C<:does> attributes, one per
role.

The package will be loaded in a similar way to how the L</:isa> attribute is
handled.

=head3 :repr(TYPE)

Sets the representation type for instances of this class. Must be one of the
following values:

   :repr(native)

The native representation. This is an opaque representation type whose
contents are not specified. It only works for classes whose entire inheritance
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

=head3 :strict(params)

I<Since version 0.43.>

Can only be applied to classes that contain no C<BUILD> blocks. If set, then
the constructor will complain about any unrecognised named arguments passed to
it (i.e. names that do not correspond to the C<:param> of any defined field
and left unconsumed by any C<ADJUST> block).

Since C<BUILD> blocks can inspect the arguments arbitrarily, the presence of
any such block means the constructor cannot determine which named arguments
are not recognised.

This attribute is a temporary stepping-stone for compatibility with existing
code. It is recommended to enable this whenever possible, as a later version
of this module will likely perform this behaviour unconditionally whenever no
C<BUILD> blocks are present.

=head2 role

   role Name :ATTRS... {
      ...
   }

   role Name :ATTRS...;

I<Since version 0.32.>

Similar to C<class>, but provides a package that defines a new role. A role
acts similar to a class in some respects, and differently in others.

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

A role can provide instance fields. These are visible to any C<BUILD> blocks
or methods provided by that role.

I<Since version 0.33.>

   role Name {
      field $f;

      BUILD { $f = "a value"; }

      method field { return $f; }
   }

I<Since version 0.57> a role can declare that it provides another role:

   role Name :does(OTHERROLE) { ... }
   role Name :does(OTHERROLE OTHERVER) { ... }

This will include all of the methods from the included role. Effectively this
means that applying the "outer" role to a class will imply applying the other
role as well.

The following role attributes are supported:

=head3 :compat(invokable)

I<Since version 0.35.>

Enables a form of backward-compatibility behaviour useful for gradually
upgrading existing code from classical Perl inheritance or mixins into using
roles.

Normally, methods of a role cannot be directly invoked and the role must be
applied to an L<Object::Pad>-based class in order to be used. This however
presents a problem when gradually upgrading existing code that already uses
techniques like roles, multiple inheritance or mixins when that code may be
split across multiple distributions, or for some other reason cannot be
upgraded all at once. Methods within a role that has the C<:compat(invokable)>
attribute applied to it may be directly invoked on any object instance. This
allows the creation of a role that can still provide code for existing classes
written in classical Perl that has not yet been rewritten to use
C<Object::Pad>.

The tradeoff is that a C<:compat(invokable)> role may not create field data
using the L</has> keyword. Whatever behaviours the role wishes to perform
must be provided only by calling other methods on C<$self>, or perhaps by
making assumptions about the representation type of instances.

It should be stressed again: This option is I<only> intended for gradual
upgrade of existing classical Perl code into using C<Object::Pad>. When all
existing code is using C<Object::Pad> then this attribute can be removed from
the role.

=head2 field

   field $var;
   field @var;
   field %var;

   field $var :ATTR ATTR...;

   field $var { BLOCK }

I<Since version 0.66.>

Declares that the instances of the class or role have a member field of the
given name. This member field will be accessible as a lexical variable within
any C<method> declarations in the class.

Array and hash members are permitted and behave as expected; you do not need
to store references to anonymous arrays or hashes.

Member fields are private to a class or role. They are not visible to users of
the class, nor inherited by subclasses nor any class that a role is applied
to. In order to provide access to them a class may wish to use L</method> to
create an accessor, or use the attributes such as L</:reader> to get one
generated.

The following field attributes are supported:

=head3 :reader, :reader(NAME)

I<Since version 0.27.>

Generates a reader method to return the current value of the field. If no name
is given, the name of the field is used. A single prefix character C<_> will
be removed if present.

   field $x :reader;

   # equivalent to
   field $x;  method x { return $x }

I<Since version 0.55> these are permitted on any field type, but prior
versions only allowed them on scalar fields. The reader method behaves
identically to how a lexical variable would behave in the same context; namely
returning a list of values from an array or key/value pairs from a hash when
in list context, or the number of items or keys when in scalar context.

   field @items :reader;

   foreach my $item ( $obj->items ) { ... }   # iterates the list of items

   my $count = $obj->items;                   # yields count of items

=head3 :writer, :writer(NAME)

I<Since version 0.27.>

Generates a writer method to set a new value of the field from its arguments.
If no name is given, the name of the field is used prefixed by C<set_>. A
single prefix character C<_> will be removed if present.

   field $x :writer;

   # equivalent to
   field $x;  method set_x { $x = shift; return $self }

I<Since version 0.28> a generated writer method will return the object
invocant itself, allowing a chaining style.

   $obj->set_x("x")
      ->set_y("y")
      ->set_z("z");

I<Since version 0.55> these are permitted on any field type, but prior
versions only allowed them on scalar fields. On arrays or hashes, the writer
method takes a list of values to be assigned into the field, completely
replacing any values previously there.

=head3 :mutator, :mutator(NAME)

I<Since version 0.27.>

Generates an lvalue mutator method to return or set the value of the field.
These are only permitted for scalar fields. If no name is given, the name of
the field is used. A single prefix character C<_> will be removed if present.

   field $x :mutator;

   # equivalent to
   field $x;  method x :lvalue { $x }

I<Since version 0.28> all of these generated accessor methods will include
argument checking similar to that used by subroutine signatures, to ensure the
correct number of arguments are passed - usually zero, but exactly one in the
case of a C<:writer> method.

=head3 :accessor, :accessor(NAME)

I<Since version 0.53.>

Generates a combined reader-writer accessor method to set or return the value
of the field. These are only permitted for scalar fields. If no name is given,
the name of the field is used. A prefix character C<_> will be removed if
present.

This method takes either zero or one additional arguments. If an argument is
passed, the value of the field is set from this argument (even if it is
C<undef>). If no argument is passed (i.e. C<scalar @_> is false) then the
field is not modified. In either case, the value of the field is then
returned.

   field $x :accessor;

   # equivalent to
   field $x;

   method field {
      $x = shift if @_;
      return $x;
   }

=head3 :weak

I<Since version 0.44.>

Generated code which sets the value of this field will weaken it if it
contains a reference. This applies to within the constructor if C<:param> is
given, and to a C<:writer> accessor method. Note that this I<only> applies to
automatically generated code; not normal code written in regular method
bodies. If you assign into the field variable you must remember to call
C<Scalar::Util::weaken> (or C<builtin::weaken> on Perl 5.36 or above)
yourself.

=head3 :param, :param(NAME)

I<Since version 0.41.>

Sets this field to be initialised automatically in the generated constructor.
This is only permitted on scalar fields. If no name is given, the name of the
field is used. A single prefix character C<_> will be removed if present.

Any field that has C<:param> but does not have a default initialisation
expression or block becomes a required argument to the constructor. Attempting
to invoke the constructor without a named argument for this will throw an
exception. In order to make a parameter optional, make sure to give it a
default expression - even if that expression is C<undef>:

   has $x :param;          # this is required
   has $z :param = undef;  # this is optional

Any field that has a C<:param> and an initialisation block will only run the
code in the block if required by the constructor. If a named parameter is
passed to the constructor for this field, then its code block will not be
executed.

Values for fields are assigned by the constructor before any C<BUILD> blocks
are invoked.

=head3 Field Initialiser Blocks

I<Since version 0.54> a deferred statement block is also permitted, on any
field variable type. This permits code to be executed as part of the instance
constructor, rather than running just once when the class is set up. Code in a
field initialisation block is roughly equivalent to being placed in a C<BUILD>
or C<ADJUST> block.

This feature should be considered B<experimental>, and will emit warnings to
that effect. They can be silenced with

   use Object::Pad qw( :experimental(init_expr) );

Control flow that attempts to leave a field initialiser block is not
permitted. This includes any C<return> expression, any C<next/last/redo>
outside of a loop, with a dynamically-calculated label expression, or with a
label that it doesn't appear in. C<goto> statements are also currently
forbidden, though known-safe ones may be permitted in future.

Loop control expressions that are known at compiletime to affect a loop that
they appear within are permitted.

   field $x { foreach(@list) { next; } }       # this is fine

   field $x { LOOP: while(1) { last LOOP; } }  # this is fine too

=head2 has

   has $var;
   has @var;
   has %var;

   has $var = EXPR;

   has $var { BLOCK }

An older version of the L</field> keyword.

This generally behaves like C<field>, except that inline expressions are also
permitted.

A scalar field may provide a expression that gives an initialisation value,
which will be assigned into the field of every instance during the constructor
before the C<BUILD> blocks are invoked. I<Since version 0.29> this expression
does not have to be a compiletime constant, though it is evaluated exactly
once, at runtime, after the class definition has been parsed. It is not
evaluated individually for every object instance of that class. I<Since
version 0.54> this is also permitted on array and hash fields.

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

   method NAME;

Declares a new named method. This behaves similarly to the C<sub> keyword,
except that within the body of the method all of the member fields are also
accessible. In addition, the method body will have a lexical called C<$self>
which contains the invocant object directly; it will already have been shifted
from the C<@_> array.

If the method has no body and is given simply as a name, this declares a
I<required> method for a role. Such a method must be provided by any class
that implements the role. It will be a compiletime error to combine the role
with a class that does not provide this.

The C<signatures> feature is automatically enabled for method declarations. In
this case the signature does not have to account for the invocant instance; 
that is handled directly.

   method m ($one, $two) {
      say "$self invokes method on one=$one two=$two";
   }

   ...
   $obj->m(1, 2);

A list of attributes may be supplied as for C<sub>. The most useful of these
is C<:lvalue>, allowing easy creation of read-write accessors for fields (but
see also the C<:reader>, C<:writer> and C<:mutator> field attributes).

   class Counter {
      field $count;

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

=head3 :common

I<Since version 0.62.>

Marks that this method is a class-common method, instead of a regular instance
method. A class-common method may be invoked on class names instead of
instances. Within the method body there is a lexical C<$class> available,
rather than C<$self>. Because it is not associated with a particular object
instance, a class-common method cannot see instance fields.

=head2 method (lexical)

   method $var { ... }

   method $var :ATTRS... (SIGNATURE) { ... }

I<Since version 0.59.>

Declares a new lexical method. Lexical methods are not visible via the package
namespace, but instead are stored directly in a lexical variable (with the
same scoping rules as regular C<my> variables). These can be invoked by
subsequent method code in the same block by using C<< $self->$var(...) >>
method call syntax.

   class WithPrivate {
      field $var;

      # Lexical methods can still see instance fields as normal
      method $inc_var { $var++; say "Var was incremented"; }
      method $dec_var { $var--; say "Var was decremented"; }

      method bump {
         $self->$inc_var;
         say "In the middle";
         $self->$dec_var;
      }
   }

   my $obj = WithPrivate->new;

   $obj->bump;

   # Neither $inc_var nor $dec_var are visible here

This effectively provides the ability to define B<private> methods, as they
are inaccessible from outside the block that defines the class. In addition,
there is no chance of a name collision because lexical variables in different
scopes are independent, even if they share the same name. This is particularly
useful in roles, to create internal helper methods without letting those
methods be visible to callers, or risking their names colliding with other
named methods defined on the consuming class.

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

Note that a C<BUILD> block is a named phaser block and not a method. Attempts
to create a method named C<BUILD> (i.e. with syntax C<method BUILD {...}>)
will fail with a compiletime error, to avoid this confusion.

=head2 ADJUST

   ADJUST {
      ...
   }

   ADJUST ( $params ) {    # on perl 5.26 onwards
      ...
   }

   ADJUST {
      my $params = shift;
      ...
   }

I<Since version 0.43.>

Declares an adjust block for this component class. This block of code runs
within the constructor, after any C<BUILD> blocks and automatic field value
assignment. It can make any final adjustments to the instance (such as
initialising fields from calculated values).

I<Since version 0.66> it receives a reference to the hash containing the
current constructor parameters. This hash will not contain any constructor
parameters already consumed by L</:param> declarations on any fields, but only
the leftovers once those are processed.

The code in the block should C<delete> from this hash any parameters it wishes
to consume. Once all the C<ADJUST> blocks have run, any remaining keys in the
hash will be considered errors, subject to the L</:strict(params)> check.

An adjust block is not a subroutine and thus is not permitted to use
subroutine attributes. Note that an C<ADJUST> block is a named phaser block
and not a method; it does not use the C<sub> or C<method> keyword.

=head2 ADJUSTPARAMS

I<Since version 0.51.>

A synonym for C<ADJUST>.

Prior to version 0.66, the C<ADJUSTPARAMS> keyword created a different kind of
adjust block that receives a reference to the parameters hash. Since version
0.66, regular C<ADJUST> blocks also receive this, so the two keywords are now
synonyms.

=head2 requires

   requires NAME;

Declares that this role requires a method of the given name from any class
that implements it. It is an error at compiletime if the implementing class
does not provide such a method.

This form of declaring a required method is now vaguely discouraged, in favour
of the bodyless C<method> form described above.

=head1 CREPT FEATURES

While not strictly part of being an object system, this module has
nevertheless gained a number of behaviours by feature creep, as they have been
found useful.

=head2 Implied Pragmata

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

=head2 Yield True

A C<class> statement or block will yield a true boolean value. This means that
it can be used directly inside a F<.pm> file, avoiding the need to explicitly
yield a true value from the end of it.

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
using C<Object::Pad> and would happen in classic Perl OO as well). The field
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

   class DerivedClass :isa(ClassicPerlBaseClass) {
      has $_value = "B";
      BUILD {
         $_value = "C";
      }
      method get_value { return $_value }
   }

   my $obj = DerivedClass->new;
   say "Value seen by user is ", $obj->get_value;

Until the C<ClassicPerlBaseClass::new> superconstructor has returned the
C<BUILD> block will not have been invoked. The C<$_value> field will still
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

=head2 Field Names

Field names should follow similar rules to regular lexical variables in code -
lowercase, name components separated by underscores. For tiny examples such as
"dumb record" structures this may be sufficient.

   class Tag {
      field $name  :mutator;
      field $value :mutator;
   }

In larger examples with lots of non-trivial method bodies, it can get
confusing to remember where the field variables come from (because we no
longer have the C<< $self->{ ... } >> visual clue). In these cases it is
suggested to prefix the field names with a leading underscore, to make them
more visually distinct.

   class Spudger {
      field $_grapefruit;

      ...

      method mangle {
         $_grapefruit->peel; # The leading underscore reminds us this is a field
      }
   }

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub _import_experimental
{
   shift;
   my ( $syms, @experiments ) = @_;

   my %enabled;

   my $i = 0;
   while( $i < @$syms ) {
      my $sym = $syms->[$i];

      if( $sym eq ":experimental" ) {
         $enabled{$_}++ for @experiments;
      }
      elsif( $sym =~ m/^:experimental\((.*)\)$/ ) {
         my $tags = $1 =~ s/^\s+|\s+$//gr; # trim
         $enabled{$_}++ for split m/\s+/, $tags;
      }
      else {
         $i++;
         next;
      }

      splice @$syms, $i, 1, ();
   }

   foreach ( @experiments ) {
      $^H{"Object::Pad/experimental($_)"}++ if delete $enabled{$_};
   }

   croak "Unrecognised :experimental features @{[ keys %enabled ]}" if keys %enabled;
}

sub _import_configuration
{
   shift;
   my ( $syms ) = @_;

   # Undocumented options, purely to support Feature::Compat::Class adjusting
   # the behaviour to closer match core's  use feature 'class'

   my $i = 0;
   while( $i < @$syms ) {
      my $sym = $syms->[$i];

      if( $sym =~ m/^:config\((.*)\)$/ ) {
         my $opts = $1 =~ s/^\s+|\s+$//gr; # trim
         $^H{"Object::Pad/configure($_)"}++ for split m/\s+/, $opts;
      }
      else {
         $i++;
         next;
      }

      splice @$syms, $i, 1, ();
   }
}

sub import_into
{
   my $class = shift;
   my $caller = shift;

   $class->_import_experimental( \@_, qw( init_expr mop custom_field_attr ) );

   $class->_import_configuration( \@_ );

   my %syms = map { $_ => 1 } @_;

   # Default imports
   unless( %syms ) {
      $syms{$_}++ for qw( class role method field has requires BUILD ADJUST );
   }

   delete $syms{$_} and $^H{"Object::Pad/$_"}++ for qw( class role method field has requires BUILD ADJUST );

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

# The universal base-class methods

sub Object::Pad::UNIVERSAL::BUILDARGS
{
   shift; # $class
   return @_;
}

# Back-compat wrapper
sub Object::Pad::MOP::SlotAttr::register
{
   shift; # $class
   carp "Object::Pad::MOP::SlotAttr->register is now deprecated; use Object::Pad::MOP::FieldAttr->register instead";
   return Object::Pad::MOP::FieldAttr->register( @_ );
}

=head1 WITH OTHER MODULES

=head2 Syntax::Keyword::Dynamically

A cross-module integration test asserts that C<dynamically> works correctly
on object instance fields:

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
ensure that object instance fields can be C<dynamically> set during a
suspended C<async method>.

=head2 Devel::MAT

When using L<Devel::MAT> to help analyse or debug memory issues with programs
that use C<Object::Pad>, you will likely want to additionally install the
module L<Devel::MAT::Tool::Object::Pad>. This will provide new commands and
extend existing ones to better assist with analysing details related to
C<Object::Pad> classes and instances of them.

   pmat> fields 0x55d7c173d4b8
   The field AV ARRAY(3)=NativeClass at 0x55d7c173d4b8
   Ix Field   Value
   0  $sfield SCALAR(UV) at 0x55d7c173d938 = 123
   ...

   pmat> identify 0x55d7c17606d8
   REF() at 0x55d7c17606d8 is:
   └─the %hfield field of ARRAY(3)=NativeClass at 0x55d7c173d4b8, which is:
   ...

=head1 DESIGN TODOs

The following points are details about the design of pad field-based object
systems in general:

=over 4

=item *

Is multiple inheritance actually required, if role composition is implemented
including giving roles the ability to use private fields?

=item *

Consider the visibility of superclass fields to subclasses. Do subclasses
even need to be able to see their superclass's fields, or are accessor methods
always appropriate?

Concrete example: The C<< $self->{split_at} >> access that
L<Tickit::Widget::HSplit> makes of its parent class
L<Tickit::Widget::LinearSplit>.

=back

=head1 IMPLEMENTATION TODOs

These points are more about this particular module's implementation:

=over 4

=item *

Consider multiple inheritance of subclassing, if that is still considered
useful after adding roles.

=item *

Work out why C<no indirect> doesn't appear to work properly before perl 5.20.

=item *

Work out why we don't get a C<Subroutine new redefined at ...> warning if we

  sub new { ... }

=item *

The C<local> modifier does not work on field variables, because they appear to
be regular lexicals to the parser at that point. A workaround is to use
L<Syntax::Keyword::Dynamically> instead:

   use Syntax::Keyword::Dynamically;

   field $loglevel;

   method quietly {
      dynamically $loglevel = LOG_ERROR;
      ...
   }

=back

=cut

=head1 FEEDBACK

The following resources are useful forms of providing feedback, especially in
the form of reports of what you find good or bad about the module, requests
for new features, questions on best practice, etc...

=over 4

=item *

The RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Object-Pad>.

=item *

The C<#cor> IRC channel on C<irc.perl.org>.

=back

=cut

=head1 SPONSORS

With thanks to the following sponsors, who have helped me be able to spend
time working on this module and other perl features.

=over 4

=item *

Oetiker+Partner AG L<https://www.oetiker.ch/en/>

=item *

Deriv L<http://deriv.com>

=item *

Perl-Verein Schweiz L<https://www.perl-workshop.ch/>

=back

Additional details may be found at
L<https://github.com/Ovid/Cor/wiki/Sponsors>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

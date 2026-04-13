package Object::Proto;
use strict;
use warnings;
our $VERSION = '0.12';
require XSLoader;
XSLoader::load('Object::Proto', $VERSION);

1;

__END__

=head1 NAME

Object::Proto - objects with prototype chains

=head1 SYNOPSIS

	use Object::Proto;

	# Define class properties (compile time)
	object 'Cat', qw(name age));

	# Positional constructor - fastest
	my $cat = new Cat 'Whiskers', 3;

	# Named pairs constructor
	my $cat = new Cat name => 'Whiskers', age => 3;

	# Accessors - compiled to custom ops
	print $cat->name;        # getter
	$cat->age(4);            # setter

	# Package methods work normally
	package Cat;
	sub speak { my $self = shift; "Meow! I am " . $self->name }

	package main;
	print $cat->speak;       # "Meow! I am Whiskers"
	print $cat->isa('Cat');  # true

	# Prototype chain
	my $proto = $cat->prototype;
	$cat->set_prototype($other);

	# Mutability controls
	$cat->lock;              # Prevent new properties
	$cat->unlock;            # Allow new properties again
	$cat->freeze;            # Permanent immutability
	$cat->is_frozen;         # Check frozen state

=head1 DESCRIPTION

C<Object::Proto> provides an alternative to C<bless> with prototype chains.
Objects are stored as arrays (not hashes) for speed, with property names
mapped to slot indices at compile time.

Objects are properly blessed into their class, so C<isa>, C<can>, and
custom package methods all work as expected.

=head1 FUNCTIONS

=head2 object $class, @properties

Define properties for a class at compile time. This assigns slot indices
and installs accessor methods. Must be called before using C<new>.

	object 'Cat', qw(name age color));

This is a convenience keyword exported by C<use Object::Proto>. It is
equivalent to calling C<Object::Proto::define()> directly.

=head2 Object::Proto::define($class, @properties)

The underlying function that C<object> delegates to. Use this form when
you need to define classes without importing the keyword, or from outside
a C<BEGIN> block:

	Object::Proto::define('Cat', qw(name age color));

Property names can include type constraints, defaults, and modifiers
using the colon-separated format:

	object 'Person',
	    'name:Str:required',           # Must provide name in new()
	    'age:Int:default(0)',          # Integer with default 0
	    'email:Str',                   # Optional string
	    'id:Str:required:readonly',    # Required, immutable after new()
	    'tags:ArrayRef:default([])',   # Fresh empty array per object
	);

=head3 Built-in Types

The following types are available with inline checks (zero overhead):

=over 4

=item * B<Any> - accepts any value

=item * B<Defined> - must be defined (not undef)

=item * B<Str> - defined non-reference

=item * B<Int> - integer value

=item * B<Num> - numeric value

=item * B<Bool> - boolean (0, 1, or empty string)

=item * B<ArrayRef> - array reference

=item * B<HashRef> - hash reference

=item * B<CodeRef> - code reference

=item * B<Object> - blessed reference

=back

=head3 Modifiers

=over 4

=item * B<required> - must be provided in new()

=item * B<readonly> - setter disabled after construction

=item * B<default(value)> - default value if not provided

=item * B<lazy> - value computed on first access (requires builder)

=item * B<builder(method)> - method name to build lazy value

=item * B<clearer> - install a clear_* method to reset value

=item * B<clearer(name)> - install clearer with custom method name

=item * B<predicate> - install a has_* method to check if set

=item * B<predicate(name)> - install predicate with custom method name

=item * B<reader(name)> - install a separate getter method (Java-style get_*)

=item * B<writer(name)> - install a separate setter method (Java-style set_*)

=item * B<trigger(method)> - method called when value changes

=item * B<weak> - weaken references stored in this slot (prevents circular refs)

=item * B<arg(name)> - use different name for constructor argument (init_arg)

=back

Default values support:

	default(0)         # integer
	default(1.5)       # number
	default(text)      # unquoted string
	default('text')    # quoted string
	default([])        # fresh empty array per object
	default({})        # fresh empty hash per object
	default(undef)     # explicit undef

=head3 Lazy and Builder

Lazy slots defer computation until first access:

	object 'Config',
	    'settings:HashRef:lazy:builder(_build_settings)',
	);

	package Config;
	sub _build_settings {
	    my $self = shift;
	    return { load_from_file() };  # Only called when accessed
	}

=head3 Clearer and Predicate

Install helper methods to clear and check slot values:

	object 'Person',
	    'nickname:Str:clearer:predicate',
	);

	my $p = new Person;
	$p->has_nickname;     # false
	$p->nickname('Bob');
	$p->has_nickname;     # true
	$p->clear_nickname;   # reset to undef
	$p->has_nickname;     # false

Custom method names can be specified:

	object 'Config',
	    'cache:HashRef:clearer(invalidate):predicate(is_cached)',
	);

	$config->is_cached;    # false
	$config->cache({});
	$config->is_cached;    # true
	$config->invalidate;   # clear the cache

=head3 Reader and Writer

For Java-style accessors, use C<reader> and C<writer> to create
separate getter and setter methods:

	object 'Person',
	    'name:Str:reader(get_name):writer(set_name)',
	);

	my $p = new Person;
	$p->set_name('Alice');
	print $p->get_name;    # "Alice"
	
	# The default accessor still works
	print $p->name;        # "Alice"

Writers enforce type constraints and fire triggers just like
the default accessor. Use with C<readonly> to prevent modification
after construction:

	object 'Entity',
	    'id:Int:readonly:reader(get_id)',  # readonly, no writer needed
	);

=head3 Weak References

Use C<weak> to automatically weaken references stored in a slot,
preventing circular reference memory leaks:

	object 'TreeNode',
	    'value:Str',
	    'parent:Object:weak',      # weak ref to parent
	    'children:ArrayRef',
	);

	my $parent = new TreeNode value => 'root';
	my $child = new TreeNode value => 'leaf', parent => $parent;
	push @{$parent->children}, $child;

	# parent->children points to child
	# child->parent points weakly to parent
	# When $parent goes out of scope and has no strong refs,
	# it will be garbage collected properly

Weak references are weakened:

=over 4

=item * At construction time when passed via constructor

=item * When set via the accessor method

=item * When set via a custom writer method

=back

=head3 Constructor Argument Names (init_arg)

Use C<arg(name)> to specify a different name for the constructor
argument. The accessor method still uses the property name:

	object 'Config',
	    'api_key:Str:required:arg(_api_key)',
	);

	# Constructor uses the init_arg name
	my $config = new Config _api_key => 'secret123';

	# Accessor uses property name
	print $config->api_key;    # "secret123"

This is useful for:

=over 4

=item * Providing a "private" constructor interface while keeping simple accessor names

=item * Migrating from other object systems that use different conventions

=item * Creating backwards-compatible APIs

=back

Combined with other modifiers:

	object 'Widget',
	    'id:Int:required:readonly:arg(_widget_id)',
	    'config:HashRef:weak:arg(_config)',
	);

=head3 Inheritance (extends)

Classes can inherit slots from a parent class using the C<extends> key:

	object 'Animal', 'name:Str:required', 'sound:Str';

	object 'Dog',
	    extends => 'Animal',
	    'breed:Str',
	);

	my $dog = new Dog name => 'Rex', sound => 'Woof', breed => 'Lab';
	print $dog->name;   # "Rex"  (inherited from Animal)
	print $dog->breed;  # "Lab"  (own slot)
	print $dog->isa('Animal');  # true

The parent class must already be defined. All parent slots are copied into
the child class, and C<@ISA> is set up automatically. The child can override
any inherited slot by redefining it:

	object 'StrictDog',
	    extends => 'Animal',
	    'name:Str:required:readonly',   # override with readonly
	    'breed:Str:required',
	);

=head4 Multiple Inheritance

Pass an arrayref to C<extends> to inherit from multiple parents:

	object 'Swimmer', 'stroke:Str';
	object 'Runner',  'pace:Num';

	object 'Triathlete',
	    extends => ['Swimmer', 'Runner'],
	    'event:Str',
	);

	my $t = new Triathlete stroke => 'freestyle', pace => 7.5, event => '70.3';
	print $t->isa('Swimmer');  # true
	print $t->isa('Runner');   # true

When multiple parents define a slot with the same name, the first parent
in the list wins. The child can always override any inherited slot.

=head4 Multi-level Inheritance

Inheritance chains work as expected:

	object 'Grandparent', 'family:Str';
	object 'Parent', extends => 'Grandparent', 'middle:Str';
	object 'Child',  extends => 'Parent', 'first:Str';

	my $c = new Child family => 'Smith', middle => 'J', first => 'Alice';
	print $c->isa('Grandparent');  # true

=head2 Object::Proto::register_type($name, $check, $coerce)

Register a custom type for use in slot specifications.

	# Simple check
	Object::Proto::register_type('PositiveInt', sub {
	    my $val = shift;
	    return $val =~ /^\d+$/ && $val > 0;
	});

	# With coercion
	Object::Proto::register_type('TrimmedStr',
	    sub { defined $_[0] && !ref $_[0] },  # check
	    sub { my $v = shift; $v =~ s/^\s+|\s+$//g; $v }  # coerce
	);

	# Now use in define
	object 'Counter',
	    'value:PositiveInt',
	    'label:TrimmedStr',
	);

=head2 Object::Proto::has_type($name)

Returns true if a type is registered (built-in or custom).

	if (Object::Proto::has_type('Email')) { ... }

=head2 Object::Proto::list_types()

Returns arrayref of all registered type names.

	my $types = Object::Proto::list_types();
	# ['Any', 'Defined', 'Str', 'Int', ... 'PositiveInt']

=head2 XS-Level Type Registration (for XS modules)

External XS modules can register types with C-level check functions
that bypass Perl callback overhead entirely (~5 cycles vs ~100 cycles).

=head3 C API Reference

Include C<object_types.h> in your XS module:

	#include "object_types.h"

=head4 object_register_type_xs

	void object_register_type_xs(pTHX_ const char *name,
	                             ObjectTypeCheckFunc check,
	                             ObjectTypeCoerceFunc coerce);

Register a type with C-level check and optional coercion functions.
Call from your BOOT section. The type name can then be used in
C<Object::Proto::define()> slot specifications.

Parameters:

=over 4

=item * C<name> - Type name (e.g., "PositiveInt", "Email")

=item * C<check> - C function to validate values (required)

=item * C<coerce> - C function to coerce values (optional, pass NULL)

=back

=head4 ObjectTypeCheckFunc

	typedef bool (*ObjectTypeCheckFunc)(pTHX_ SV *val);

Type check function signature. Return true if value passes the check.

=head4 ObjectTypeCoerceFunc

	typedef SV* (*ObjectTypeCoerceFunc)(pTHX_ SV *val);

Type coercion function signature. Return the coerced value (may be
the same SV or a new mortal). Return NULL if coercion fails.

=head4 object_get_registered_type

	RegisteredType* object_get_registered_type(pTHX_ const char *name);

Look up a registered type by name. Returns NULL if not found.
Useful for introspection or chaining type checks.

=head3 Complete Example

	/* MyTypes.xs */
	#define PERL_NO_GET_CONTEXT
	#include "EXTERN.h"
	#include "perl.h"
	#include "XSUB.h"
	#include "object_types.h"

	static bool check_positive_int(pTHX_ SV *val) {
	    if (!SvIOK(val) && !(SvPOK(val) && looks_like_number(val)))
	        return false;
	    return SvIV(val) > 0;
	}

	static bool check_email(pTHX_ SV *val) {
	    if (SvROK(val)) return false;
	    STRLEN len;
	    const char *pv = SvPV(val, len);
	    const char *at = memchr(pv, '@', len);
	    return at && at != pv && at != pv + len - 1;
	}

	static SV* coerce_trim(pTHX_ SV *val) {
	    STRLEN len;
	    const char *pv = SvPV(val, len);
	    const char *start = pv;
	    const char *end = pv + len;
	    while (start < end && isSPACE(*start)) start++;
	    while (end > start && isSPACE(*(end-1))) end--;
	    return sv_2mortal(newSVpvn(start, end - start));
	}

	MODULE = MyTypes  PACKAGE = MyTypes

	BOOT:
	    object_register_type_xs(aTHX_ "PositiveInt", check_positive_int, NULL);
	    object_register_type_xs(aTHX_ "Email", check_email, NULL);
	    object_register_type_xs(aTHX_ "TrimmedStr", NULL, coerce_trim);

Usage in Perl:

	use MyTypes;  # Registers types in BOOT
	use Object::Proto;

	object 'User',
	    'id:PositiveInt:required',
	    'email:Email',
	    'bio:TrimmedStr',
	);

	my $user = new User id => 42, email => 'user@example.com';

=head3 Performance Tiers

	Type Source               Check Cost    Total Overhead
	--------------------------------------------------------
	Built-in (Str, Int)       ~0 cycles     inline switch
	Registered C function     ~5 cycles     function pointer
	Perl callback             ~100 cycles   call_sv overhead

=head3 Linking

Your XS module needs to link against the Object::Proto module. The functions
are exported with C<PERL_CALLCONV> visibility.

=head2 new $class @args

Create a new object. Supports positional or named arguments.

	my $cat = new Cat 'Whiskers', 3;           # positional
	my $cat = new Cat name => 'Whiskers';      # named

=head2 $obj->prototype

Get the prototype object (or undef if none).

=head2 $obj->set_prototype($proto)

Set the prototype object. Fails if object is frozen.

=head2 Object::Proto::prototype_chain($obj)

Return the full prototype chain as an arrayref, starting from C<$obj>
and following each prototype link. Detects and stops on circular
references.

	my $chain = Object::Proto::prototype_chain($cat);
	# [$cat, $proto, $proto_of_proto, ...]

=head2 Object::Proto::prototype_depth($obj)

Return the depth of the prototype chain (number of prototypes above
this object). Returns 0 if the object has no prototype.

	my $depth = Object::Proto::prototype_depth($cat);  # 0, 1, 2, ...

=head2 Object::Proto::has_own_property($obj, $property)

Return true if the object has a defined value for the given property
in its own slots (not inherited via prototype chain).

	if (Object::Proto::has_own_property($cat, 'name')) { ... }

=head2 $obj->lock

Prevent adding new properties. Can be unlocked.

=head2 $obj->unlock

Allow adding new properties again. Fails if frozen.

=head2 $obj->freeze

Permanently prevent modifications. Cannot be undone.

=head2 $obj->is_frozen

Returns true if object is frozen.

=head2 $obj->is_locked

Returns true if object is locked (but may not be frozen).

=head2 Object::Proto::clone($obj)

Create a shallow copy of an object. All property values are copied, but
references share the same underlying referent. The clone is a fresh object
that is NOT frozen or locked, even if the original was.

	my $original = new Cat name => 'Whiskers', age => 3;
	Object::Proto::freeze($original);

	my $clone = Object::Proto::clone($original);
	$clone->age(4);  # works - clone is not frozen
	print $clone->name;  # "Whiskers"

Shallow copy means array/hash reference properties will share data:

	$original->tags(['fluffy']);
	my $clone = $original->clone;
	push @{$clone->tags}, 'playful';
	# $original->tags is now ['fluffy', 'playful']

=head2 Object::Proto::properties($class)

Return the property names for a class. In list context, returns the property
names. In scalar context, returns the count.

	my @props = Object::Proto::properties('Cat');   # ('name', 'age')
	my $count = Object::Proto::properties('Cat');   # 2

	# Check if property exists
	if (grep { $_ eq 'color' } Object::Proto::properties('Cat')) {
	    ...
	}

Returns an empty list (or 0 in scalar context) for non-existent classes.

=head2 Object::Proto::slot_info($class, $property)

Return detailed metadata about a property slot. Returns a hashref with
information about the slot, or C<undef> if the class or property doesn't
exist.

	my $info = Object::Proto::slot_info('Person', 'name');
	# Returns:
	# {
	#     name         => 'name',
	#     index        => 1,
	#     type         => 'Str',
	#     is_required  => 1,
	#     is_readonly  => 0,
	#     is_lazy      => 0,
	#     has_default  => 0,
	#     has_trigger  => 0,
	#     has_coerce   => 0,
	#     has_builder  => 0,
	#     has_clearer  => 0,
	#     has_predicate => 0,
	#     has_type     => 1,
	# }

The returned hash always contains these boolean flags:

=over 4

=item * B<is_required> - Property must be provided in new()

=item * B<is_readonly> - Setter disabled after construction

=item * B<is_lazy> - Value computed on first access

=item * B<has_default> - Has a default value

=item * B<has_trigger> - Has a trigger callback

=item * B<has_coerce> - Has coercion enabled

=item * B<has_builder> - Has a builder method

=item * B<has_clearer> - Has a clearer method

=item * B<has_predicate> - Has a predicate method

=item * B<has_type> - Has a type constraint

=back

Additional keys may be present depending on the slot configuration:

=over 4

=item * B<type> - The type name (if has_type is true)

=item * B<default> - The default value (if has_default is true)

=item * B<builder> - The builder method name (if has_builder is true)

=back

=head2 Object::Proto::parent($class)

Return the parent class(es) of a class. In scalar context, returns the
first (or only) parent class name, or C<undef> if none. In list context,
returns all parent class names.

	object 'Animal', 'name:Str';
	object 'Dog', extends => 'Animal', 'breed:Str';

	my $p = Object::Proto::parent('Dog');     # 'Animal'
	my @p = Object::Proto::parent('Dog');     # ('Animal')

	object 'Hybrid', extends => ['Dog', 'Cat'];
	my $first = Object::Proto::parent('Hybrid');  # 'Dog'
	my @all   = Object::Proto::parent('Hybrid');  # ('Dog', 'Cat')

Returns C<undef>/empty list for classes with no parent.

=head2 Object::Proto::ancestors($class)

Return all ancestor classes in breadth-first order, with duplicates
removed. Useful for inspecting the full inheritance hierarchy.

	object 'A', 'a:Str';
	object 'B', extends => 'A', 'b:Str';
	object 'C', extends => 'B', 'c:Str';

	my @anc = Object::Proto::ancestors('C');  # ('B', 'A')

For multiple inheritance with diamond patterns, each ancestor appears
only once (first occurrence wins):

	object 'Base', 'x:Str';
	object 'Left',  extends => 'Base';
	object 'Right', extends => 'Base';
	object 'Diamond', extends => ['Left', 'Right'];

	my @anc = Object::Proto::ancestors('Diamond');
	# ('Left', 'Right', 'Base')  -- Base appears once

=head2 Object::Proto::import_accessors($class, $prefix, $target)

Import function-style accessors for maximum performance. This enables
calling accessors as C<name $obj> instead of C<$obj-E<gt>name>, which
avoids method dispatch overhead.

	# In a BEGIN block so call checker sees the functions
	BEGIN {
	    use Object::Proto;
	    object 'Cat', qw(name age));
	    Object::Proto::import_accessors('Cat');  # imports to current package
	}

	my $cat = new Cat 'Whiskers', 3;

	# Function-style - 2.4x faster GET, 4x faster SET
	my $n = name $cat;
	age $cat, 4;

	# Method-style still works
	my $n = $cat->name;
	$cat->age(4);

The optional C<$prefix> parameter prepends a string to each imported
accessor name, which is useful for avoiding name collisions when
importing from multiple classes:

	BEGIN {
	    Object::Proto::define('Dog', qw(name breed));
	    Object::Proto::define('Cat', qw(name color));
	    Object::Proto::import_accessors('Dog', 'dog_');
	    Object::Proto::import_accessors('Cat', 'cat_');
	}

	my $d = new Dog name => 'Rex', breed => 'Lab';
	dog_name $d;    # 'Rex'
	dog_breed $d;   # 'Lab'

The optional C<$target> parameter specifies which package to import into
(defaults to caller). Pass C<undef> for C<$prefix> to skip prefixing
when specifying a target:

	Object::Proto::import_accessors('Cat', undef, 'MyPackage');

=head2 Object::Proto::import_accessor($class, $prop, $alias, $target)

Import a single accessor with an optional alias name.

	BEGIN {
	    use Object::Proto;
	    object 'Cat', qw(name age));
	    Object::Proto::import_accessor('Cat', 'name', 'get_name');
	    Object::Proto::import_accessor('Cat', 'age', 'set_age');
	}

	my $cat = new Cat 'Whiskers', 3;
	my $n = get_name $cat;   # same as name($cat)
	set_age $cat, 4;         # same as age($cat, 4)

Parameters:

=over 4

=item * C<$class> - The class name

=item * C<$prop> - The property name to access

=item * C<$alias> - The function name to install (defaults to C<$prop>)

=item * C<$target> - Package to install into (defaults to caller)

=back

Function-style accessors are compiled to custom ops at compile time,
giving performance competitive with or faster than C<slot>.

=head1 BUILD

Define a C<BUILD> method in your class to run initialization code
after object construction. C<BUILD> is called automatically after
C<new()> with the fully constructed object as its argument.

	package Counter;
	use Object::Proto;

	object 'Counter', 'count', 'label:Str';

	sub BUILD {
	    my ($self) = @_;
	    $self->count(0);
	}

	package main;
	my $c = new Counter label => 'hits';
	$c->count;  # 0 (set by BUILD)

All constructor arguments are applied before C<BUILD> runs, so you
can read slot values in your BUILD method:

	package Derived;
	object 'Derived', 'x', 'y', 'sum';

	sub BUILD {
	    my ($self) = @_;
	    $self->sum(($self->x // 0) + ($self->y // 0));
	}

	my $d = new Derived x => 3, y => 4;
	$d->sum;  # 7

When a child class inherits via C<extends>, the child's C<BUILD>
method is called (not the parent's). Call the parent's BUILD
explicitly if needed.

Zero overhead: BUILD is detected lazily on first C<new()> call,
and the lookup is cached.

=head1 DEMOLISH

Define a C<DEMOLISH> method in your class to run cleanup code when
objects are destroyed. The C<Object::Proto> module automatically installs
a C<DESTROY> wrapper that calls your C<DEMOLISH> method.

	package FileHandle;

	sub DEMOLISH {
	    my $self = shift;
	    close $self->fh if $self->fh;
	}

	package main;
	object 'FileHandle', 'fh', 'path:Str');

Zero overhead: The DESTROY wrapper is only installed for classes that
define a DEMOLISH method.

=head1 SINGLETONS

=head2 Object::Proto::singleton($class)

Mark a class as a singleton. This installs a C<< $class->instance() >>
method that always returns the same object.

	package Config;
	BEGIN {
	    Object::Proto::define('Config', 'debug:Bool:default(0)');
	    Object::Proto::singleton('Config');
	}

	sub BUILD {
	    my ($self) = @_;
	    # initialization runs once, on first instance() call
	}

	package main;
	my $cfg  = Config->instance;
	my $same = Config->instance;  # same object

The instance is created lazily on the first call to C<instance()>.
If the class defines a C<BUILD> method, it is called after construction.
The class must already be defined with C<Object::Proto::define()>.

=head1 ROLES

Roles provide reusable bundles of slots and methods that can be composed
into classes. Zero overhead if not used.

=head2 Object::Proto::role($name, @slot_specs)

Define a role with slots:

	Object::Proto::role('Serializable', 'format:Str:default(json)');

	package Serializable;
	sub serialize {
	    my $self = shift;
	    return $self->format eq 'json' ? to_json($self) : to_yaml($self);
	}

=head2 Object::Proto::requires($role, @method_names)

Declare methods that consuming classes must implement:

	Object::Proto::requires('Serializable', 'to_hash');

=head2 Object::Proto::with($class, @roles)

Compose roles into a class:

	object 'Document', 'title:Str', 'content:Str');
	Object::Proto::with('Document', 'Serializable');

	my $doc = new Document title => 'Test', content => 'Hello';
	print $doc->format;      # 'json' (from role)
	print $doc->serialize;   # JSON output

=head2 Object::Proto::does($obj_or_class, $role)

Check if an object or class consumes a role:

	if (Object::Proto::does($doc, 'Serializable')) { ... }

=head1 METHOD MODIFIERS

Wrap existing methods with before, after, or around hooks. Zero overhead
for classes that don't use modifiers.

=head2 Object::Proto::before($method, $callback)

Run code before a method. Arguments are passed to the callback.

	Object::Proto::before('Person::save', sub {
	    my ($self) = @_;
	    $self->updated_at(time);
	});

=head2 Object::Proto::after($method, $callback)

Run code after a method. Arguments are passed to the callback.

	Object::Proto::after('Person::save', sub {
	    my ($self) = @_;
	    log_action("Saved person: " . $self->name);
	});

=head2 Object::Proto::around($method, $callback)

Wrap a method. Receives C<$orig> as first argument:

	Object::Proto::around('Person::age', sub {
	    my ($orig, $self, @args) = @_;
	    if (@args) {
	        die "Age must be positive" if $args[0] < 0;
	    }
	    return $self->$orig(@args);
	});

Multiple modifiers can be stacked:

	Object::Proto::before('Class::method', \&first);
	Object::Proto::before('Class::method', \&second);  # runs before first
	Object::Proto::after('Class::method', \&third);    # runs after method
	Object::Proto::after('Class::method', \&fourth);   # runs after third

=head1 BENCHMARK

	#!/usr/bin/env perl
	use strict;
	use warnings;
	use Benchmark qw(:all);

	use Object::Proto;

	# Define classes in BEGIN so call checkers work
	BEGIN {
		# Object::Proto (XS) - no types
		Object::Proto::define('Person', qw(name age score));

		# Object::Proto (XS) - with types
		Object::Proto::define('TypedPerson', 'name:Str', 'age:Int', 'score:Num');

		# Import function-style accessors
		Object::Proto::import_accessors('Person');
	}

	package PureHash {
		sub new {
			my ($class, %args) = @_;
			return bless { name => $args{name}, age => $args{age}, score => $args{score} }, $class;
		}
		sub name  { @_ > 1 ? $_[0]->{name}  = $_[1] : $_[0]->{name}  }
		sub age   { @_ > 1 ? $_[0]->{age}   = $_[1] : $_[0]->{age}   }
		sub score { @_ > 1 ? $_[0]->{score} = $_[1] : $_[0]->{score} }
	}

	package PureArray {
		use constant { NAME => 0, AGE => 1, SCORE => 2 };
		sub new {
			my ($class, %args) = @_;
			return bless [ $args{name}, $args{age}, $args{score} ], $class;
		}
		sub name  { @_ > 1 ? $_[0]->[NAME]  = $_[1] : $_[0]->[NAME]  }
		sub age   { @_ > 1 ? $_[0]->[AGE]   = $_[1] : $_[0]->[AGE]   }
		sub score { @_ > 1 ? $_[0]->[SCORE] = $_[1] : $_[0]->[SCORE] }
	}

	print "\n\nTest: Mixed new->set->get (5 seconds)\n";
	print "-" x 40, "\n";

	my $r = timethese(-5, {
		'Raw Hash' => sub {
			my %hh = ( name => 'Alice', age => 30, score => 95.5 );
			$hh{age} = 31;
			my $x = $hh{age};
		},
		'Raw Hash Ref' => sub {
			my $h = { name => 'Alice', age => 30, score => 95.5 };
			$h->{age} = 31;
			my $x = $h->{age};
		},
		'Pure Hash' => sub {
			my $pure_hash  = PureHash->new(name => 'Bob', age => 25, score => 88.0);
			$pure_hash->age(31);
			my $x = $pure_hash->age;
		},
		'Pure Array' => sub {
			my $pure_array = PureArray->new(name => 'Bob', age => 25, score => 88.0);
			$pure_array->age(31);
			my $x = $pure_array->age;
		},
		'Object::Proto (XS OO)' => sub {
			my $obj_xs = new Person name => 'Bob', age => 25, score => 88.0;
			$obj_xs->age(31);
			my $x = $obj_xs->age;
		},
		'Object::Proto (XS func)' => sub {
			my $obj_xs = new Person 'Bob', 25, 88.0;
			age($obj_xs, 31);
			my $x = age($obj_xs);
		},
		'Object::Proto typed' => sub {
			my $obj_typed  = new TypedPerson 'Bob', 25, 88.0;
			age $obj_typed, 31;
			my $x = age $obj_typed;
		},
	});

	cmpthese $r;

	Test: Mixed new->set->get (5 seconds)
	----------------------------------------
	Benchmark: running Object::Proto (XS OO), Object::Proto (XS func), Object::Proto typed, Pure Array, Pure Hash, Raw Hash, Raw Hash Ref for at least 5 CPU seconds...
	^[[B^[[BObject::Proto (XS OO):  5 wallclock secs ( 5.43 usr +  0.01 sys =  5.44 CPU) @ 3541833.27/s (n=19267573)
	Object::Proto (XS func):  6 wallclock secs ( 5.38 usr +  0.01 sys =  5.39 CPU) @ 5427162.15/s (n=29252404)
	Object::Proto typed:  4 wallclock secs ( 5.00 usr +  0.00 sys =  5.00 CPU) @ 5114882.60/s (n=25574413)
	Pure Array:  6 wallclock secs ( 5.12 usr +  0.01 sys =  5.13 CPU) @ 2124356.53/s (n=10897949)
	 Pure Hash:  4 wallclock secs ( 5.00 usr +  0.01 sys =  5.01 CPU) @ 1824921.36/s (n=9142856)
	  Raw Hash:  5 wallclock secs ( 5.32 usr +  0.01 sys =  5.33 CPU) @ 6024884.24/s (n=32112633)
	Raw Hash Ref:  3 wallclock secs ( 5.01 usr +  0.01 sys =  5.02 CPU) @ 5331773.11/s (n=26765501)
				     Rate Pure Hash Pure Array Object::Proto (XS OO) Object::Proto typed Raw Hash Ref Object::Proto (XS func) Raw Hash
	Pure Hash               1824921/s        --       -14%                  -48%                -64%         -66%                    -66%     -70%
	Pure Array              2124357/s       16%         --                  -40%                -58%         -60%                    -61%     -65%
	Object::Proto (XS OO)   3541833/s       94%        67%                    --                -31%         -34%                    -35%     -41%
	Object::Proto typed     5114883/s      180%       141%                   44%                  --          -4%                     -6%     -15%
	Raw Hash Ref            5331773/s      192%       151%                   51%                  4%           --                     -2%     -12%
	Object::Proto (XS func) 5427162/s      197%       155%                   53%                  6%           2%                      --     -10%
	Raw Hash                6024884/s      230%       184%                   70%                 18%          13%                     11%       --

... If you only instantiate once and then only set/get inside the benchmark


	Test: Mixed set/get (5 seconds)
	----------------------------------------
	Benchmark: running Object::Proto (XS OO), Object::Proto (XS func), Object::Proto typed, Pure Array, Pure Hash, Raw Hash, Raw Hash Ref for at least 5 CPU seconds...
	Object::Proto (XS OO):  5 wallclock secs ( 5.17 usr +  0.00 sys =  5.17 CPU) @ 13893769.44/s (n=71830788)
	Object::Proto (XS func):  5 wallclock secs ( 5.13 usr + -0.01 sys =  5.12 CPU) @ 32693120.12/s (n=167388775)
	Object::Proto typed:  4 wallclock secs ( 5.00 usr +  0.02 sys =  5.02 CPU) @ 31742847.21/s (n=159349093)
	Pure Array:  5 wallclock secs ( 5.02 usr +  0.02 sys =  5.04 CPU) @ 7287556.94/s (n=36729287)
	 Pure Hash:  6 wallclock secs ( 5.30 usr + -0.00 sys =  5.30 CPU) @ 6991138.87/s (n=37053036)
	  Raw Hash:  5 wallclock secs ( 5.22 usr +  0.02 sys =  5.24 CPU) @ 25955432.82/s (n=136006468)
	Raw Hash Ref:  5 wallclock secs ( 5.33 usr +  0.02 sys =  5.35 CPU) @ 24923303.55/s (n=133339674)
				      Rate Pure Hash Pure Array Object::Proto (XS OO) Raw Hash Ref Raw Hash Object::Proto typed Object::Proto (XS func)
	Pure Hash                6991139/s        --        -4%                  -50%         -72%     -73%                -78%                    -79%
	Pure Array               7287557/s        4%         --                  -48%         -71%     -72%                -77%                    -78%
	Object::Proto (XS OO)   13893769/s       99%        91%                    --         -44%     -46%                -56%                    -58%
	Raw Hash Ref            24923304/s      256%       242%                   79%           --      -4%                -21%                    -24%
	Raw Hash                25955433/s      271%       256%                   87%           4%       --                -18%                    -21%
	Object::Proto typed     31742847/s      354%       336%                  128%          27%      22%                  --                     -3%
	Object::Proto (XS func) 32693120/s      368%       349%                  135%          31%      26%                  3%                      --


=head1 AUTHOR

LNATION E<email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

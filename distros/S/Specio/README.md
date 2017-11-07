# NAME

Specio - Type constraints and coercions for Perl

# VERSION

version 0.42

# SYNOPSIS

    package MyApp::Type::Library;

    use Specio::Declare;
    use Specio::Library::Builtins;

    declare(
        'PositiveInt',
        parent => t('Int'),
        inline => sub {
            $_[0]->parent->inline_check( $_[1] )
                . ' && ( '
                . $_[1]
                . ' > 0 )';
        },
    );

    # or ...

    declare(
        'PositiveInt',
        parent => t('Int'),
        where  => sub { $_[0] > 0 },
    );

    declare(
        'ArrayRefOfPositiveInt',
        parent => t(
            'ArrayRef',
            of => t('PositiveInt'),
        ),
    );

    coerce(
        'ArrayRefOfPositiveInt',
        from  => t('PositiveInt'),
        using => sub { [ $_[0] ] },
    );

    any_can_type(
        'Duck',
        methods => [ 'duck_walk', 'quack' ],
    );

    object_isa_type('MyApp::Person');

# DESCRIPTION

The `Specio` distribution provides classes for representing type constraints
and coercion, along with syntax sugar for declaring them.

Note that this is not a proper type system for Perl. Nothing in this
distribution will magically make the Perl interpreter start checking a value's
type on assignment to a variable. In fact, there's no built-in way to apply a
type to a variable at all.

Instead, you can explicitly check a value against a type, and optionally
coerce values to that type.

My long-term goal is to replace Moose's built-in types and [MooseX::Types](https://metacpan.org/pod/MooseX::Types)
with this module.

# WHAT IS A TYPE?

At it's core, a type is simply a constraint. A constraint is code that checks
a value and returns true or false. Most constraints are represented by
[Specio::Constraint::Simple](https://metacpan.org/pod/Specio::Constraint::Simple) objects. However, there are other type
constraint classes for specialized kinds of constraints.

Types can be named or anonymous, and each type can have a parent type. A
type's constraint is optional because sometimes you may want to create a named
subtype of some existing type without adding additional constraints.

Constraints can be expressed either in terms of a simple subroutine reference
or in terms of an inline generator subroutine reference. The former is easier
to write but the latter is preferred because it allow for better optimization.

A type can also have an optional message generator subroutine reference. You
can use this to provide a more intelligent error message when a value does not
pass the constraint, though the default message should suffice for most cases.

Finally, you can associate a set of coercions with a type. A coercion is a
subroutine reference (or inline generator, like constraints), that takes a
value of one type and turns it into a value that matches the type the coercion
belongs to.

# BUILTIN TYPES

This distribution ships with a set of builtin types representing the types
provided by the Perl interpreter itself. They are arranged in a hierarchy as
follows:

    Item
        Bool
        Maybe (of `a)
        Undef
        Defined
            Value
                Str
                    Num
                        Int
                    ClassName
            Ref
                ScalarRef (of `a)
                ArrayRef (of `a)
                HashRef (of `a)
                CodeRef
                RegexpRef
                GlobRef
                FileHandle
                Object

The `Item` type accepts anything and everything.

The `Bool` type only accepts `undef`, `0`, or `1`.

The `Undef` type only accepts `undef`.

The `Defined` type accepts anything _except_ `undef`.

The `Num` and `Int` types are stricter about numbers than Perl
is. Specifically, they do not allow any sort of space in the number, nor do
they accept "Nan", "Inf", or "Infinity".

The `ClassName` type constraint checks that the name is valid _and_ that the
class is loaded.

The `FileHandle` type accepts either a glob, a scalar filehandle, or anything
that isa [IO::Handle](https://metacpan.org/pod/IO::Handle).

All types accept overloaded objects that support the required operation. See
below for details.

## Overloading

Perl's overloading is horribly broken and doesn't make much sense at all.

However, unlike Moose, all type constraints allow overloaded objects where
they make sense.

For types where overloading makes sense, we explicitly check that the object
provides the type overloading we expect. We _do not_ simply try to use the
object as the type in question and hope it works. This means that these checks
effectively ignore the `fallback` setting for the overloaded object. In other
words, an object that overloads stringification will not pass the `Bool` type
check unless it _also_ overloads boolification.

Most types do not check that the overloaded method actually returns something
that matches the constraint. This may change in the future.

The `Bool` type accepts an object that implements `bool` overloading.

The `Str` type accepts an object that implements string (`q{""}`)
overloading.

The `Num` type accepts an object that implements numeric (`'0+'}`)
overloading. The `Int` type does as well, but it will check that the
overloading returns an actual integer.

The `ClassName` type will accept an object with string overloading that
returns a class name.

To make this all more confusing, the `Value` type will _never_ accept an
object, even though some of its subtypes will.

The various reference types all accept objects which provide the appropriate
overloading. The `FileHandle` type accepts an object which overloads
globification as long as the returned glob is an open filehandle.

# PARAMETERIZABLE TYPES

Any type followed by a type parameter `` of `a `` in the hierarchy above can be
parameterized. The parameter is itself a type, so you can say you want an
"ArrayRef of Int", or even an "ArrayRef of HashRef of ScalarRef of ClassName".

When they are parameterized, the `ScalarRef` and `ArrayRef` types check that
the value(s) they refer to match the type parameter. For the `HashRef` type,
the parameter applies to the values (keys are never checked).

## Maybe

The `Maybe` type is a special parameterized type. It allows for either
`undef` or a value. All by itself, it is meaningless, since it is equivalent
to "Maybe of Item", which is equivalent to Item. When parameterized, it
accepts either an `undef` or the type of its parameter.

This is useful for optional attributes or parameters. However, you're probably
better off making your code simply not pass the parameter at all This usually
makes for a simpler API.

# REGISTRIES AND IMPORTING

Types are local to each package where they are used. When you "import" types
from some other library, you are actually making a copy of that type.

This means that a type named "Foo" in one package may not be the same as "Foo"
in another package. This has potential for confusion, but it also avoids the
magic action at a distance pollution that comes with a global type naming
system.

The registry is managed internally by the Specio distribution's modules, and is
not exposed to your code. To access a type, you always call `t('TypeName')`.

This returns the named type or dies if no such type exists.

Because types are always copied on import, it's safe to create coercions on
any type. Your coercion from `Str` to `Int` will not be seen by any other
package, unless that package explicitly imports your `Int` type.

When you import types, you import every type defined in the package you import
from. However, you _can_ overwrite an imported type with your own type
definition. You _cannot_ define the same type twice internally.

# CREATING A TYPE LIBRARY

By default, all types created inside a package are invisible to other
packages. If you want to create a type library, you need to inherit from
[Specio::Exporter](https://metacpan.org/pod/Specio::Exporter) package:

    package MyApp::Type::Library;

    use parent 'Specio::Exporter';

    use Specio::Declare;
    use Specio::Library::Builtins;

    declare(
        'Foo',
        parent => t('Str'),
        where  => sub { $_[0] =~ /foo/i },
    );

Now the MyApp::Type::Library package will export a single type named
`Foo`. It _does not_ re-export the types provided by
[Specio::Library::Builtins](https://metacpan.org/pod/Specio::Library::Builtins).

If you want to make your library re-export some other libraries types, you can
ask for this explicitly:

    package MyApp::Type::Library;

    use parent 'Specio::Exporter';

    use Specio::Declare;
    use Specio::Library::Builtins -reexport;

    declare( 'Foo, ... );

Now MyApp::Types::Library exports any types it defines, as well as all the
types defined in [Specio::Library::Builtins](https://metacpan.org/pod/Specio::Library::Builtins).

# DECLARING TYPES

Use the [Specio::Declare](https://metacpan.org/pod/Specio::Declare) module to declare types. It exports a set of helpers
for declaring types. See that module's documentation for more details on these
helpers.

# USING SPECIO WITH [Moose](https://metacpan.org/pod/Moose)

This should just work. Use a Specio type anywhere you'd specify a type.

# USING SPECIO WITH [Moo](https://metacpan.org/pod/Moo)

Using Specio with Moo is easy. You can pass Specio constraint objects as
`isa` parameters for attributes. For coercions, simply call `$type->coercion_sub`.

    package Foo;

    use Specio::Declare;
    use Specio::Library::Builtins;
    use Moo;

    my $str_type = t('Str');
    has string => (
       is  => 'ro',
       isa => $str_type,
    );

    my $ucstr = declare(
        'UCStr',
        parent => t('Str'),
        where  => sub { $_[0] =~ /^[A-Z]+$/ },
    );

    coerce(
        $ucstr,
        from  => t('Str'),
        using => sub { return uc $_[0] },
    );

    has ucstr => (
        is     => 'ro',
        isa    => $ucstr,
        coerce => $ucstr->coercion_sub,
    );

The subs returned by Specio use [Sub::Quote](https://metacpan.org/pod/Sub::Quote) internally and are suitable for
inlining.

# USING SPECIO WITH OTHER THINGS

See [Specio::Constraint::Simple](https://metacpan.org/pod/Specio::Constraint::Simple) for the API that all constraint objects
share.

# [Moose](https://metacpan.org/pod/Moose), [MooseX::Types](https://metacpan.org/pod/MooseX::Types), and Specio

This module aims to supplant both [Moose](https://metacpan.org/pod/Moose)'s built-in type system (see
[Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose::Util::TypeConstraints) aka MUTC) and [MooseX::Types](https://metacpan.org/pod/MooseX::Types), which attempts
to patch some of the holes in the Moose built-in type design.

Here are some of the salient differences:

- Types names are strings, but they're not global

    Unlike Moose and MooseX::Types, type names are always local to the current
    package. There is no possibility of name collision between different modules,
    so you can safely use short type names.

    Unlike MooseX::Types, types are strings, so there is no possibility of
    colliding with existing class or subroutine names.

- No type auto-creation

    Types are always retrieved using the `t()` subroutine. If you pass an unknown
    name to this subroutine it dies. This is different from Moose and
    MooseX::Types, which assume that unknown names are class names.

- Anon types are explicit

    With [Moose](https://metacpan.org/pod/Moose) and [MooseX::Types](https://metacpan.org/pod/MooseX::Types), you use the same subroutine, `subtype()`,
    to declare both named and anonymous types. With Specio, you use `declare()` for
    named types and `anon()` for anonymous types.

- Class and object types are separate

    Moose and MooseX::Types have `class_type` and `duck_type`. The former type
    requires an object, while the latter accepts a class name or object.

    With Specio, the distinction between accepting an object versus object or
    class is explicit. There are six declaration helpers, `object_can_type`,
    `object_does_type`, `object_isa_type`, `any_can_type`, `any_does_type`,
    and `any_isa_type`.

- Overloading support is baked in

    Perl's overloading is quite broken but ignoring it makes Moose's type system
    frustrating to use in many cases.

- Types can either have a constraint or inline generator, not both

    Moose and MooseX::Types types can be defined with a subroutine reference as
    the constraint, an inline generator subroutine, or both. This is purely for
    backwards compatibility, and it makes the internals more complicated than they
    need to be.

    With Specio, a constraint can have _either_ a subroutine reference or an
    inline generator, not both.

- Coercions can be inlined

    I simply never got around to implementing this in Moose.

- No crazy coercion features

    Moose has some bizarre (and mostly) undocumented features relating to
    coercions and parameterizable types. This is a misfeature.

# WHY THE NAME?

This distro was originally called "Type", but that's an awfully generic top
level namespace. Specio is Latin for for "look at" and "spec" is the root for
the word "species". It's short, relatively easy to type, and not used by any
other distro.

# LONG-TERM PLANS

Eventually I'd like to see this distro replace Moose's internal type system,
which would also make MooseX::Types obsolete.

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Specio/issues](https://github.com/houseabsolute/Specio/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Specio can be found at [https://github.com/houseabsolute/Specio](https://github.com/houseabsolute/Specio).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- cpansprout <cpansprout@gmail.com>
- Graham Knop <haarg@haarg.org>
- Karen Etheridge <ether@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 - 2017 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.

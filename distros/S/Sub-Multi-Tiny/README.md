[![Build Status](https://travis-ci.org/cxw42/Sub-Multi-Tiny.svg?branch=master)](https://travis-ci.org/cxw42/Sub-Multi-Tiny)
# NAME

Sub::Multi::Tiny - Multisubs/multimethods (multiple dispatch) yet another way!

# SYNOPSIS

    {
        package main::my_multi;     # We're making main::my_multi()
        use Sub::Multi::Tiny qw($foo $bar);     # All possible params

        sub first :M($foo, $bar) {  # sub's name will be ignored,
            return $foo ** $bar;    # but can't match the one we're making
        }

        sub second :M($foo) {
            return $foo + 42;
        }

    }

    # Back in package main, my_multi() is created just before the run phase.
    say my_multi(2, 5);     # -> 32
    say my_multi(1295);     # -> 1337

The default dispatcher dispatches solely by arity, and only one
candidate can have each arity.  For more flexible dispatching, see
[Sub::Multi::Tiny::Dispatcher::TypeParams](https://metacpan.org/pod/Sub%3A%3AMulti%3A%3ATiny%3A%3ADispatcher%3A%3ATypeParams).

# DESCRIPTION

Sub::Multi::Tiny is a library for making multisubs, aka multimethods,
aka multiple-dispatch subroutines.  Each multisub is defined in a
single package.  Within that package, the individual implementations ("impls")
are `sub`s tagged with the `:M` attribute.  The names of the impls are
preserved but not used specifically by Sub::Multi::Tiny.

Within a multisub package, the name of the sub being defined is available
for recursion.  For example (using `where`, supported by
[Sub::Multi::Tiny::Dispatcher::TypeParams](https://metacpan.org/pod/Sub%3A%3AMulti%3A%3ATiny%3A%3ADispatcher%3A%3ATypeParams)):

    {
        package main::fib;
        use Sub::Multi::Tiny qw(D:TypeParams $n);
        sub base  :M($n where { $_ <= 1 })  { 1 }
        sub other :M($n)                    { $n * fib($n-1) }
    }

This code creates function `fib()` in package `main`.  Within package
`main::fib`, function `fib()` is an alias for `main::fib()`.  It's easier
to use than to explain!

# FUNCTIONS

## import

Sets up the package that uses it to define a multisub.  The parameters
are all the parameter variables that the multisubs will use.  `import`
creates these as package variables so that they can be used unqualified
in the multisub implementations.

A parameter `D:Dispatcher` can also be given to specify the dispatcher to
use --- see ["CUSTOM DISPATCH"](#custom-dispatch).

Also sets ["$VERBOSE" in Sub::Multi::Tiny::Util](https://metacpan.org/pod/Sub%3A%3AMulti%3A%3ATiny%3A%3AUtil#VERBOSE) if the environment variable
`SUB_MULTI_TINY_VERBOSE` has a truthy value.  If the `SUB_MULTI_TINY_VERBOSE`
value is numeric, `$VERBOSE` is set to that value; otherwise, `$VERBOSE` is
set to 1.

# CUSTOM DISPATCH

This module includes a default dispatcher (implemented in
[Sub::Multi::Tiny::Dispatcher::Default](https://metacpan.org/pod/Sub%3A%3AMulti%3A%3ATiny%3A%3ADispatcher%3A%3ADefault).  To use a different dispatcher,
define or import a sub `MakeDispatcher()` into the package before
compilation ends.  That sub will be called to create the dispatcher.
For example:

    {
        package main::foo;
        use Sub::Multi::Tiny;
        sub MakeDispatcher { return sub { ... } }
    }

or

    {
        package main::foo;
        use Sub::Multi::Tiny;
        use APackageThatImportsMakeDispatcherIntoMainFoo;
    }

As a shortcut, you can specify a dispatcher on the `use` line.  For example:

    use Sub::Multi::Tiny qw(D:Foo $var);

will use dispatcher `Sub::Multi::Tiny::Dispatcher::Foo`.  Any name with a
double-colon will be used as a full package name.  E.g., `D:Bar::Quux` will
use dispatcher `Bar::Quux`.  If `Foo` does not include a double-colon,
`Sub::Multi::Tiny::Dispatcher::` will be prepended.

# DEBUGGING

For extra debug output, set ["$VERBOSE" in Sub::Multi::Tiny::Util](https://metacpan.org/pod/Sub%3A%3AMulti%3A%3ATiny%3A%3AUtil#VERBOSE) to a positive
integer.  This has to be set at compile time to have any effect.  For example,
before creating any multisubs, do:

    use Sub::Multi::Tiny::Util '*VERBOSE';
    BEGIN { $VERBOSE = 2; }

# RATIONALE

- To be able to use multisubs in pre-5.14 Perls with only built-in
language facilities.  This will help me make my own modules backward
compatible with those Perls.
- To learn how it's done! :)

# SEE ALSO

I looked at these but decided not to use them for the following reasons:

- [Class::Multimethods](https://metacpan.org/pod/Class%3A%3AMultimethods)

    I wanted a syntax that used normal `sub` definitions as much as possible.
    Also, I was a bit concerned by LPALMER's experience that it "does what you
    don't want sometimes without saying a word"
    (["Semantics" in Class::Multimethods::Pure](https://metacpan.org/pod/Class%3A%3AMultimethods%3A%3APure#Semantics)).

    Other than that, I think this looks pretty decent (but haven't tried it).

- [Class::Multimethods::Pure](https://metacpan.org/pod/Class%3A%3AMultimethods%3A%3APure)

    Same desire for `sub` syntax.  Additionally, the last update was in 2007,
    and the maintainer hasn't uploaded anything since.  Other than that, I think
    this also looks like a decent option (but haven't tried it).

- [Dios](https://metacpan.org/pod/Dios)

    This is a full object system, which I do not need in my use case.

- [Logic](https://metacpan.org/pod/Logic)

    This one is fairly clean, but uses a source filter.  I have not had much
    experience with source filters, so am reluctant.

- [Kavorka::Manual::MultiSubs](https://metacpan.org/pod/Kavorka%3A%3AManual%3A%3AMultiSubs) (and [Moops](https://metacpan.org/pod/Moops))

    Requires Perl 5.14+.

- [MooseX::MultiMethods](https://metacpan.org/pod/MooseX%3A%3AMultiMethods)

    I am not ready to move to full [Moose](https://metacpan.org/pod/Moose)!

- [MooseX::Params](https://metacpan.org/pod/MooseX%3A%3AParams)

    As above.

- [Sub::Multi](https://metacpan.org/pod/Sub%3A%3AMulti)

    The original inspiration for this module, whence this module's name.
    `Sub::Multi` uses coderefs, and I wanted a syntax that used normal
    `sub` definitions as much as possible.

- [Sub::SmartMatch](https://metacpan.org/pod/Sub%3A%3ASmartMatch)

    This one looks very interesting, but I haven't used smartmatch enough
    to be fully comfortable with it.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Multi::Tiny

You can also look for information at:

- GitHub: The project's main repository and issue tracker

    [https://github.com/cxw42/Sub-Multi-Tiny](https://github.com/cxw42/Sub-Multi-Tiny)

- MetaCPAN

    [Sub::Multi::Tiny](https://metacpan.org/pod/Sub%3A%3AMulti%3A%3ATiny)

- This distribution

    See the tests in the `t/` directory distributed with this software
    for usage examples.

# BUGS

- It's not as tiny as I thought it would be!
- This isn't Damian code ;) .

# AUTHOR

Chris White <cxw@cpan.org>

# LICENSE

Copyright (C) 2019 Chris White <cxw@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

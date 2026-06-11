# NAME

Sub::Abstract - Abstract (virtual) methods for plain-Perl OO

# VERSION

Version 0.01

# SYNOPSIS

    package Animal;
    use Sub::Abstract;

    # Attribute form (stub body required for Attribute::Handlers)
    sub speak :Abstract { }
    sub eat   :Abstract { }

    # Declarative form (no stub body needed)
    use Sub::Abstract qw(speak eat);

    package Dog;
    our @ISA = ('Animal');
    sub speak { 'Woof' }    # satisfies the contract; wrapper never fires
    # forgot eat -- runtime croak when called

# DESCRIPTION

Enforces abstract (virtual) method contracts for plain-Perl OO without
requiring Moose or Moo.  A subroutine decorated with `:Abstract` (or
named in `use Sub::Abstract qw(...)`) is replaced at `CHECK` time with
a wrapper that `Carp::croak`s whenever it is reached.

Perl's MRO ensures the wrapper is only reached when no subclass in the
call chain has provided an implementation: if `Dog::speak` exists, the
wrapper installed in `Animal::speak` is never called.

This module is only meaningful for plain-Perl OO or packages that do not
use a full object framework.  Moo and Moose handle abstract/required
methods in their own object systems.

## Two usage forms

- Attribute form (preferred)

        sub speak :Abstract { }

    The `:Abstract` attribute is registered in `UNIVERSAL` via
    [Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers) when `Sub::Abstract` is loaded, so every package
    has access to it without further `use` or inheritance.  A stub body
    (even an empty one) is required because `Attribute::Handlers` needs a
    `CODE` ref.  The stub is replaced at `CHECK` time.

- Declarative form

        use Sub::Abstract qw(speak eat);

    Each named method is installed as an abstract-croak wrapper at `CHECK`
    time (or immediately if the module is loaded past `CHECK`).  No stub body
    is needed.

## Bypass for testing

Either condition alone (OR logic) suppresses the croak:

- `$Sub::Abstract::BYPASS` set to a true value.  Use `local` in tests.
- `$ENV{HARNESS_ACTIVE}` set (the convention used by [Test::Harness](https://metacpan.org/pod/Test%3A%3AHarness)/prove).

The `HARNESS_ACTIVE` bypass can be disabled:

    $Sub::Abstract::config{harness_bypass} = 0;

## Error message format

    speak() is an abstract method of Animal and must be implemented by Dog

# PUBLIC INTERFACE

## import

    use Sub::Abstract;                   # attribute form -- no arguments
    use Sub::Abstract qw(speak eat);    # declarative form

### Purpose

With **no arguments**: makes the `:Abstract` attribute globally available.

With **one or more method names**: installs abstract-croak wrappers for
those methods in the calling package at `CHECK` time (or immediately if
`CHECK` has already fired).

### Arguments

- `@methods` (optional)

    Zero or more Perl sub names, each matching `/\A[_a-zA-Z]\w*\z/`.

### Returns

The class name (`'Sub::Abstract'`) as a plain string.

### MESSAGES

    Message                                              Meaning
    ---------------------------------------------------  -----------------------------------------------
    "Sub::Abstract->import: 'NAME' is not a valid        A name failed the identifier regex.
     Perl identifier"

# KNOWN LIMITATIONS

- Runtime-only

    Checks are runtime only.  There is no compile-time scan of `@ISA` trees
    to verify that all abstract methods are implemented -- that would require
    knowing all subclasses at compile time, which is not possible in general Perl.

- `can()` returns the croak-stub

    Because the stash entry is replaced with a wrapper closure,
    `Animal->can('speak')` returns the wrapper (truthy) rather than
    `undef`.  A future release may add a caller-aware `can()` override.

- UNIVERSAL namespace pollution

    The `:Abstract` attribute is installed in `UNIVERSAL`, which means
    `UNIVERSAL::Abstract` is added to the global namespace.

- Not for Moo/Moose

    Moo and Moose handle required/abstract methods in their own object systems.
    This module is for plain-Perl OO only.

# DEPENDENCIES

[Carp](https://metacpan.org/pod/Carp) (core),
[Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers) (core since 5.8),
[Readonly](https://metacpan.org/pod/Readonly),
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict),
[Return::Set](https://metacpan.org/pod/Return%3A%3ASet).

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Sub-Abstract/coverage/)
- [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate)

    Sister module enforcing strictly private (owner-only) access.

- [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected)

    Sister module enforcing protected (owner + subclass) access.

# PUBLIC VARIABLES

## `$BYPASS`

Set to a true value to disable the abstract-method croak for all wrapped
subs.  Use `local` in tests:

    local $Sub::Abstract::BYPASS = 1;

## `%config`

- `harness_bypass` (default: 1)

    When true, the abstract-method croak is suppressed whenever
    `$ENV{HARNESS_ACTIVE}` is set (the convention used by [Test::Harness](https://metacpan.org/pod/Test%3A%3AHarness)/prove).
    Set to 0 to test enforcement from within a test harness.

# FORMAL SPECIFICATION

The following Z-notation schemas formally specify the `AbstractCroak`
operation.

    -- Type abbreviations
    Package  == seq CHAR     -- a non-empty Perl package name string
    SubName  == seq CHAR     -- a Perl identifier string

    -- System state
    +-Registry-------------------------------------------+
    | abstract  : P (Package x SubName)                  |
    | bypass    : BOOL                                   |
    | config    : { harness_bypass : BOOL }              |
    +----------------------------------------------------+

    -- Initial state
    +-InitRegistry---------------------------------------+
    | Registry                                           |
    |----------------------------------------------------|
    | abstract  = {}                                     |
    | bypass    = false                                  |
    | config    = { harness_bypass |-> true }            |
    +----------------------------------------------------+

    -- Bypass predicate
    bypass_active(R) <=>
        R.bypass or (R.config.harness_bypass and HARNESS_ACTIVE)

    -- AbstractCroak: fires when the wrapper is reached (no override in MRO)
    +-AbstractCroak--------------------------------------+
    | Xi-Registry                                        |
    | invocant? : Package                                |
    | owner?    : Package                                |
    | name?     : SubName                                |
    |----------------------------------------------------|
    | (owner?, name?) in abstract                        |
    | not bypass_active =>                               |
    |   croak("name?()" ++ " is an abstract method of " |
    |          ++ owner? ++ " and must be implemented by"|
    |          ++ invocant?)                             |
    +----------------------------------------------------+

    -- Key difference from Sub::Private / Sub::Protected:
    --   No caller check is performed.  The wrapper always croaks
    --   because reaching it means no subclass provided an implementation.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

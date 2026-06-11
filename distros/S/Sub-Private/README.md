# NAME

Sub::Private - Private subroutines and methods

# VERSION

Version 0.05

# SYNOPSIS

    package Foo;
    use Sub::Private;

    sub foo { return 42 }

    sub bar :Private {
        return foo() + 1;
    }

    sub baz {
        return bar() + 1;
    }

# DESCRIPTION

Enforces strictly private access on subroutines.  A subroutine decorated
with `:Private` (or named in `use Sub::Private qw(...)` when in enforce
mode) may only be called from within its defining package.  Subclasses do
not inherit access: private means _this package only_.

## Two enforcement modes

- `namespace` mode (default, backward-compatible)

    Removes the subroutine from the package symbol table using
    [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean).  Direct (non-method) function calls compiled before
    cleanup still work because Perl optimises them to direct opcode references.
    OO method dispatch (`$self-`name>) does not work for private subs in this
    mode because method lookup uses the symbol table at runtime.

    This is the default mode and is backward-compatible with all existing code.

- `enforce` mode (OO-safe, opt-in)

    Replaces the subroutine with a wrapper closure that checks `caller` at
    call time and either delegates (owner package) or croaks (anyone else).
    Works correctly with OO dispatch (`$self-`\_helper>).

    Enable before declaring your first private sub:

        BEGIN { $Sub::Private::config{mode} = 'enforce' }
        package MyClass;
        use Sub::Private;
        sub _helper :Private { ... }

## Bypass for testing

Either condition alone (OR logic) disables all access checks in enforce
mode:

- `$Sub::Private::BYPASS` set to a true value.  Use `local` in
tests.
- `$ENV{HARNESS_ACTIVE}` set (the convention used by
[Test::Harness](https://metacpan.org/pod/Test%3A%3AHarness)/prove).

`$Sub::Private::BYPASS` is the recommended form for new test code.
The `HARNESS_ACTIVE` bypass can be disabled:

    $Sub::Private::config{harness_bypass} = 0;

## Configuration

    $Sub::Private::config{mode}            -- 'namespace' (default) or 'enforce'
    $Sub::Private::config{harness_bypass}  -- 1 (default); set to 0 to test enforcement

## Error message format (enforce mode)

    bar() is a private subroutine of Foo and cannot be called from Bar

# PUBLIC VARIABLES

## `$BYPASS`

Set to a true value to disable all access checks (enforce mode only).
Use `local` in tests; see ["Bypass for testing"](#bypass-for-testing).

## `%config`

Module-level configuration hash.  Supported keys:

- `mode`

    `'namespace'` (default) or `'enforce'`.  Must be set in a `BEGIN`
    block before `use Sub::Private` to take effect at `CHECK` time.

- `harness_bypass`

    When true (default), access checks are skipped whenever
    `$ENV{HARNESS_ACTIVE}` is set.  Set to 0 to test enforcement under
    `prove`.

# PUBLIC INTERFACE

## import

    use Sub::Private;                    # attribute form -- no arguments
    use Sub::Private qw(_a _b _c);      # declarative form (enforce mode only)

### Purpose

Called automatically by `use Sub::Private`.

With **no arguments**: makes the `:Private` attribute globally available
via `UNIVERSAL`.  No other action is taken.

With **one or more sub names**: registers those named subs in the calling
package for access-enforcement wrapping at `CHECK` time.  If `CHECK`
has already fired (e.g., when calling from a test), wrapping is applied
immediately.  Requires `$Sub::Private::config{mode}` to equal
`'enforce'`; croaks otherwise.

### Arguments

- `@subs` (optional)

    Zero or more Perl sub names.  Each must be a defined, non-reference scalar
    matching `/\A[_a-zA-Z]\w*\z/`.  `undef`, references, empty strings, and
    names starting with a digit or containing hyphens are all rejected.

### Returns

The class name (`'Sub::Private'`) as a plain string in all cases.

### Side effects

- Pre-CHECK: appends `[$owner_pkg, $sub_name]` pairs to the
internal `@_pending` list.
- Post-CHECK: installs wrapper closures directly in the calling
package's stash.

### Example

    BEGIN { $Sub::Private::config{mode} = 'enforce' }
    package MyClass;
    use Sub::Private qw(_helper _init);

    sub new     { bless {}, shift }
    sub _helper { ... }    # wrapped at CHECK time
    sub _init   { ... }    # wrapped at CHECK time
    sub run     { my $s = shift; $s->_helper; $s->_init }

### API specification

#### Input

    # No-argument form: always valid.
    Sub::Private->import();

    # Declarative form (enforce mode only):
    {
        subs => {
            type     => 'array',
            optional => 1,
            element  => {
                type  => 'string',
                regex => qr/\A[_a-zA-Z]\w*\z/,
            },
        }
    }

#### Output

    { type => 'string' }    # returns the class name 'Sub::Private'

### MESSAGES

    Message                                              Meaning / Action
    ---------------------------------------------------  -----------------------------------------------
    "Sub::Private->import: declarative form requires     use Sub::Private qw(...) was called while
     mode => 'enforce'"                                  $config{mode} is not 'enforce'.  Set
                                                         $config{mode} = 'enforce' in a BEGIN block
                                                         before "use Sub::Private".

    "Sub::Private->import: 'NAME' is not a valid         The sub name failed the identifier regex.
     Perl identifier"                                    Check for typos, hyphens, leading digits,
                                                         undef, or reference values in the import list.

    "Sub::Private: PKG::NAME is not defined"             The named sub was not found in the stash at
                                                         wrap time.  Define the sub before import()
                                                         runs, or before CHECK fires.

# KNOWN LIMITATIONS

- `namespace` mode: OO dispatch fails for private subs

    `$self-`\_helper> from within the owner package fails because method
    dispatch uses the symbol table at runtime, which no longer contains the
    entry.  Use `enforce` mode for OO classes.

- `enforce` mode: runtime-only

    Checks are runtime only; there is no compile-time enforcement.

- `enforce` mode: raw coderef bypass

    A raw code reference obtained **before** wrapping (via `can()` or
    `\&Foo::_helper`) bypasses the check.  The attribute form prevents this
    because wrapping happens at CHECK time.

- `enforce` mode: `can()` leaks private method existence

    In `enforce` mode the original sub is replaced by a wrapper closure, so
    `->can('_helper')` returns the wrapper (truthy) even to callers outside
    the owner package.  In `namespace` mode the stash entry is deleted entirely,
    so `->can` correctly returns `undef`.  A future release may inject a
    caller-aware `can()` override into each class that uses `enforce` mode,
    returning the coderef only when the caller is the owner package and `undef`
    for everyone else.

- UNIVERSAL namespace pollution

    The `:Private` attribute is installed in `UNIVERSAL`, which is
    intentional (any package can use it after a single `use`), but it does
    introduce `UNIVERSAL::Private` into the global namespace.

# DEPENDENCIES

[Carp](https://metacpan.org/pod/Carp) (core),
[Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers) (core since 5.8),
[Readonly](https://metacpan.org/pod/Readonly),
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict),
[Return::Set](https://metacpan.org/pod/Return%3A%3ASet),
[namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean),
[Sub::Identify](https://metacpan.org/pod/Sub%3A%3AIdentify).

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Sub-Private/coverage/)
- [Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected)

    Sister module enforcing protected (owner + subclass) rather than strictly private access

- [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean)

## FORMAL SPECIFICATION

The following Z-notation schemas formally specify the `CheckAccess`
operation.

    -- Type abbreviations
    Package  == seq CHAR     -- a non-empty Perl package name string
    SubName  == seq CHAR     -- a Perl identifier string

    -- Private-access predicate (strictly owner only -- no isa expansion)
    permitted : Package x Package -> BOOL
    forall caller, owner : Package .
        permitted(caller, owner) <=> caller = owner

    -- System state
    +-Registry-------------------------------------------+
    | private   : P (Package x SubName)                  |
    | bypass    : BOOL                                    |
    | config    : { mode : seq CHAR,                      |
    |               harness_bypass : BOOL }               |
    +----------------------------------------------------+

    -- Initial state
    +-InitRegistry---------------------------------------+
    | Registry                                           |
    |----------------------------------------------------|
    | private   = {}                                     |
    | bypass    = false                                  |
    | config    = { mode |-> 'namespace',                 |
    |               harness_bypass |-> true }             |
    +----------------------------------------------------+

    -- Bypass predicate
    bypass_active(R) <=>
        R.bypass or (R.config.harness_bypass and HARNESS_ACTIVE)

    -- Access check: no state change
    +-CheckAccess----------------------------------------+
    | Xi-Registry                                        |
    | caller? : Package                                  |
    | owner?  : Package                                  |
    | name?   : SubName                                  |
    | ok!     : BOOL                                     |
    |----------------------------------------------------|
    | (owner?, name?) in private                         |
    | ok! <=> bypass_active or permitted(caller?, owner?)|
    +----------------------------------------------------+

    -- Violation (croak case):
    --   not ok! =>
    --   croak("name?()" ++ " is a private subroutine of " ++ owner?
    --         ++ " and cannot be called from " ++ caller?)

    -- Key difference from Sub::Protected:
    --   permitted(caller, owner) <=> caller = owner   (identity only)
    -- vs Sub::Protected:
    --   permitted(caller, owner) <=> owner in anc(caller)   (ISA chain)

# AUTHOR

Original Author:
Peter Makholm, `<peter at makholm.net>`

Current maintainer:
Nigel Horne, `<njh at nigelhorne.com>`

# BUGS

Please report any bugs or feature requests to `bug-sub-private at rt.cpan.org`,
or through the web interface at
[https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Private](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Private).

# SUPPORT

    perldoc Sub::Private

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Private](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Private)

- Search CPAN

    [https://search.cpan.org/dist/Sub-Private](https://search.cpan.org/dist/Sub-Private)

## FORMAL SPECIFICATION

### import

    -- Type abbreviations
    SubName == seq CHAR      -- non-empty Perl identifier string

    -- Valid identifier predicate
    valid_id : SubName -> BOOL
    valid_id(n) <=> n =~ /\A[_a-zA-Z]\w*\z/

    -- Pre-condition (declarative form)
    +-ImportPre-----------------------------------------+
    | config.mode = 'enforce'                           |
    | forall n in subs . valid_id(n)                    |
    | forall n in subs . defined(&{caller + '::' + n})  |
    +---------------------------------------------------+

    -- Post-condition (pre-CHECK path)
    +-ImportPost_PreCheck-------------------------------+
    | @_pending' = @_pending                            |
    |            union { (caller, n) | n in subs }      |
    +---------------------------------------------------+

    -- Post-condition (post-CHECK path)
    +-ImportPost_PostCheck------------------------------+
    | forall n in subs .                                |
    |   stash(caller, n) = wrapper_closure(caller, n)   |
    +---------------------------------------------------+

# COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm, all rights reserved.
Portions copyright 2024-2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

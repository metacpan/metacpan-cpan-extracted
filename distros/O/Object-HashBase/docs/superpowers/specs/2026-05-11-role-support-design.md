# Object::HashBase Role Support — Design

Date: 2026-05-11

## Summary

Add two new single-character import prefixes to `Object::HashBase`:

- `@Class::Name` — load `Class::Name`, push it onto consumer's `@ISA` (parent shortcut, replaces `use parent`).
- `&Role::Name` — load `Role::Name`, verify it is a `Role::Tiny` role that uses `Object::HashBase`, copy its accessor constants into the consumer at compile time, and defer `Role::Tiny->apply_roles_to_package` until end of consumer's compile scope.

Additionally, when `Object::HashBase` is imported by a package that is itself a `Role::Tiny` role, skip injection of `new`, `add_pre_init`, `add_post_init`, `_pre_init`, `_post_init`. Roles get accessors and constants only.

`Moose::Role` is explicitly out of scope. Nobody combines Moose with Object::HashBase.

## Motivation

Current Object::HashBase usage in roles is broken in two ways:

1. Importing in a Role::Tiny role package injects `new`, which is wrong for roles.
2. Consumers of such a role cannot use the `$self->{+FOO}` constant pattern, because `Role::Tiny` composes via `with()` at runtime, after consumer subs have already compiled and failed `strict subs` on the undeclared `FOO` bareword.

The `&` prefix solves both: it imports role constants eagerly at compile time (so `+FOO` resolves in consumer subs), while deferring the actual `with()` composition until after consumer subs are compiled (so role method composition, modifiers, and required-method checks behave correctly).

The `@` prefix is a convenience: eliminates the need for `use parent 'Foo';` or `use base 'Foo';` before `use Object::HashBase`.

## Prefix Specification

### `@Parent::Class`

- `require Parent::Class` at import time.
- Croak on require failure with caller-context error.
- Push `Parent::Class` onto `@{"$into\::ISA"}` if not already present.
- Existing `_isa` walk in `do_import` then picks up parent's constants and methods.

### `&Role::Name`

- If `Role::Tiny` is not already loaded, attempt `require Role::Tiny`. Croak only if load fails (Role::Tiny not installed). Object::HashBase does NOT declare `Role::Tiny` as a dependency in metadata — it is a soft requirement triggered only by use of the `&` prefix.
- `require Role::Name` at import time.
- Croak unless `Role::Tiny->is_role('Role::Name')`.
- Croak unless `$Object::HashBase::ATTR_LIST{'Role::Name'}` is defined (role must use Object::HashBase).
- Croak unless `$] >= 5.010` (the deferred-compose trick requires reliable `%^H`).
- Copy each constant from `$Object::HashBase::ATTR_SUBS{'Role::Name'}` into `$into` immediately, so `+FOO` resolves in consumer subs compiled after the `use` statement.
- Register a pending `apply_roles_to_package($into, 'Role::Name')` call to fire at end of consumer's compile scope via the `%^H` DESTROY trick.

## Role Detection on Import

Add `_is_role($pkg)` helper:

```perl
sub _is_role {
    my $pkg = shift;
    return 0 unless $INC{'Role/Tiny.pm'};
    return Role::Tiny->is_role($pkg) ? 1 : 0;
}
```

In `do_import`, if `_is_role($into)` is true:

- Skip the `_build_new` call entirely.
- Do not register `$into`'s new in `$Object::HashBase::NEW_LOOKUP`.
- Still install accessors and constants for the role's own attribute list.

This means `package MyRole; use Role::Tiny; use Object::HashBase qw/foo -bar/;` will install `foo`, `set_foo`, `FOO`, `BAR` into `MyRole` but no `new`. Consumers of `MyRole` get those methods via Role::Tiny composition.

## Deferred Role Composition via `%^H`

Defer `Role::Tiny->apply_roles_to_package` so consumer's own methods, method modifiers, and required-method requirements are satisfied at compose time.

Inline package `Object::HashBase::_RoleApplier` inside `lib/Object/HashBase.pm` (no new file):

```perl
package    # hide from PAUSE indexer
    Object::HashBase::_RoleApplier;

sub new {
    my ($class, $into) = @_;
    return bless { into => $into, roles => [] }, $class;
}

sub add { push @{$_[0]->{roles}}, $_[1] }

sub DESTROY {
    my $self = shift;
    return unless @{$self->{roles}};
    Role::Tiny->apply_roles_to_package($self->{into}, @{$self->{roles}});
}
```

In `do_import`, when processing one or more `&Role` prefixes:

```perl
my $key = "Object::HashBase::role_applier::$into";
my $applier = $^H{$key} ||= Object::HashBase::_RoleApplier->new($into);
$applier->add($role);
```

When the compile scope containing the `use` statement ends, Perl destroys `%^H`, our object's `DESTROY` fires, and roles are composed in the order they were added.

Multiple `use Object::HashBase '&Role::A', '&Role::B';` calls in the same scope share the same applier (via the per-`$into` key), so all roles compose at once at end of scope.

### Perl 5.10+ Requirement

The `%^H` DESTROY trick relies on `%^H` being properly lexically scoped during compile, which was made reliable in Perl 5.10.0. Object::HashBase as a whole keeps its `use 5.008001` minimum; the `&` prefix specifically croaks on Perl older than 5.10:

```perl
Carp::croak("Object::HashBase '&' role prefix requires Perl 5.010 or newer (this is $])")
    if $] < 5.010;
```

Other features (the `@` prefix, role-detection-skip-new) work on 5.8.x without issue.

## Processing Order in `do_import`

1. Walk `@_` once. Classify each arg by `substr($x, 0, 1)`:
   - `'@'` → parent. Strip prefix, push to `@parents`.
   - `'&'` → role. Strip prefix, push to `@roles`.
   - else → attr. Push to `@attrs`.
2. For each parent in `@parents`: require and push to `@{"$into\::ISA"}`.
3. `_is_role($into)` check (note: must happen AFTER `Role::Tiny` may have been loaded by consumer, but we don't load it here — consumer loads it before `use Object::HashBase`).
4. Build subs hash:
   - `_build_new` only if not a role and no inherited `new` (existing logic).
   - Inherited `ATTR_SUBS` walk over `@ISA` (existing logic, now includes any parents added in step 2).
   - `args_to_subs(\@attrs, ...)` for own attrs.
5. Install subs.
6. For each role in `@roles`: if `Role::Tiny` not loaded, `require Role::Tiny` (croak on failure); then `require` role, verify it is a Role::Tiny role with HashBase attrs, eager-copy constants, register with applier in `%^H`.

This order ensures parent constants are in scope before role constants (so role can see parent constants if needed), and own constants are in scope before role composition (matters for role method modifiers that reference own methods).

## Error Cases

All errors use `Carp::croak` so they report from the consumer's `use` line.

- `@Parent` where `require` fails: `Could not load parent class 'Parent': $@`
- `&Role` when Role::Tiny not loaded and cannot be loaded: `Object::HashBase '&' role prefix requires Role::Tiny but it could not be loaded: $@`
- `&Role` on perl < 5.10: `Object::HashBase '&' role prefix requires Perl 5.010 or newer`
- `&Role` where `require` fails: `Could not load role 'Role': $@`
- `&Role` where target is not a Role::Tiny role: `'Role' is not a Role::Tiny role`
- `&Role` where target has no Object::HashBase attrs: `'Role' does not use Object::HashBase`

## Test Plan

All test files use `Test2::V0` and skip when Role::Tiny missing.

### `t/parent_prefix.t`

No skip — `@` prefix has no extra deps.

- Define `My::Parent` with `use Object::HashBase qw/pa/;`
- Define `My::Child` with `use Object::HashBase qw/@My::Parent ch/;`
- Verify `My::Child->isa('My::Parent')`
- Verify `My::Child->new(pa => 1, ch => 2)` returns object with both attrs
- Verify `My::Child` has `PA` and `CH` constants
- Verify `My::Child->new->pa` and `->ch` accessors work
- Verify `set_pa`, `set_ch` work
- Verify `@My::Parent` ordering: parent constants visible to child attrs that follow in same `use` line
- Verify `require` failure on bogus parent name croaks from caller

### `t/role_prefix.t`

`use Test2::Require::Module 'Role::Tiny';`
`use Test2::Require::Perl '5.010';`

- Define `My::Role` with `use Role::Tiny; use Object::HashBase qw/ra/;`
- Verify `My::Role` has `RA`, `ra`, `set_ra` installed
- Verify `My::Role` does NOT have `new`, `add_pre_init`, `add_post_init` installed
- Verify `Role::Tiny->is_role('My::Role')` is true
- Define `My::Consumer` with `use Object::HashBase qw/&My::Role co/;` and a sub using `$self->{+RA}` and `$self->{+CO}` (this tests compile-time constant visibility)
- Verify `My::Consumer->new(ra => 'x', co => 'y')->ra` returns `'x'`
- Verify `Role::Tiny::does_role('My::Consumer', 'My::Role')` is true
- Verify consumer's own sub overrides role's same-named method (test deferred compose)
- Test method modifier scenario: role uses `around 'method' => sub { ... }`, consumer defines `method`, verify wrapping works (this is the key reason for deferred compose)
- Test required method: role declares `requires 'foo'`, consumer that lacks `foo` fails at compose time (end of scope)
- Test multiple roles: `use Object::HashBase '&My::Role::A', '&My::Role::B';` — both composed
- Error cases: `&NonExistent` croaks, `&PlainClass` (not a role) croaks, `&RoleWithoutHashBase` croaks

### `t/role_auto_load.t`

`use Test2::Require::Module 'Role::Tiny';`
`use Test2::Require::Perl '5.010';`

Verify `&` prefix works WITHOUT consumer explicitly loading Role::Tiny first — Object::HashBase loads it on demand. Construct a role and consumer where neither calls `use Role::Tiny` directly in the consumer; the role itself uses Role::Tiny (must, to be a role).

(There is no test for "Role::Tiny missing entirely" — that scenario cannot be unit-tested without uninstalling Role::Tiny. The croak path is reviewed by inspection.)

### `t/role_old_perl.t`

Skipped on perl 5.10+. On 5.8.x, verify `&` prefix croaks with version message.

## POD Updates

Add new section "ISA AND ROLE PREFIXES" between "ACCESSORS" and "SUBCLASSING":

- Document `@Class::Name` shortcut for parent. Show example replacing `use parent 'Foo'; use Object::HashBase qw/bar/;` with `use Object::HashBase qw/@Foo bar/;`.
- Document `&Role::Name` for Role::Tiny role consumption. Explain compile-time constant import + deferred `with()`. Show example.

Add new section "USING IN A ROLE":

- Show `package MyRole; use Role::Tiny; use Object::HashBase qw/foo bar/;` pattern.
- Note: no `new` is injected; consumer provides construction.
- Note: role's `attr_list` reflects only the role's own attrs; consumer's `attr_list` does not see role attrs (array-form constructor with role attrs not supported).
- Document Perl 5.10 minimum for `&` prefix.

## Files Changed

- `lib/Object/HashBase.pm` — prefix dispatch, `_is_role`, `_RoleApplier` inline package, POD additions.
- `t/parent_prefix.t` — new
- `t/role_prefix.t` — new
- `t/role_auto_load.t` — new
- `t/role_old_perl.t` — new
- `Changes` — entry under next version section

## Out of Scope

- Moose::Role support.
- New `Object::HashBase::Test` cases for these features (the standalone test files cover them; `Test.pm` exists for inline-copy testing and adding role-aware test cases there would force the inline copy to depend on Role::Tiny test-time).
- Updating the inline-copy mechanism (`Inline.pm`) to add role support — it inherits the changes automatically since it copies `HashBase.pm` content. But the role-consumer would need Role::Tiny at consumer site regardless.

## Addendum: 2026-05-11 Review Feedback

The following refinements are required based on architectural review:

### 1. Unified `attr_list` Support
While originally "Out of Scope", excluding role attributes from `attr_list()` breaks the `MyClass->new([$val1, $val2])` array-ref constructor for consumers.
- **Requirement:** Track role attributes in a shared global (e.g., `%Object::HashBase::ROLE_ATTRS`).
- **Requirement:** Update `Object::HashBase::attr_list()` to include attributes from composed roles.

### 2. `do_import` Refactoring
The processing order must strictly ensure `@ISA` is updated *before* the constant walk.
- **Requirement:** `do_import` must first parse all arguments to identify `@Parent` prefixes and update `@ISA`.
- **Requirement:** Call `_isa($into)` only *after* the `@ISA` updates are complete to ensure the inherited constant collection is fresh.

### 3. `Role::Tiny` Versioning
The `Role::Tiny->is_role($pkg)` method was introduced in version **1.003000**.
- **Requirement:** If `Role::Tiny` is found but the version is too old to support `is_role`, provide a clear error message.

### 4. Constant Conflict Resolution
Eager-copying role constants might collide with subs already defined in the consumer (or installed by an earlier `use` in the same package).
- **Policy:** If a sub of the same name already exists in `$into` at the time we would copy a role constant, keep the existing sub. Do not override. Do not warn. The consumer's existing definition wins silently.
- This applies to constants copied from `&Role` imports only. Parent inheritance via `@Parent` continues to use the existing `ATTR_SUBS` walk behavior (no change).

### 5. Interaction with `Inline.pm`
The `%^H` key `"Object::HashBase::role_applier::$into"` will be transformed to `"$prefix\::HashBase::role_applier::$into"` by the inliner. This is desired as it isolates different inlined versions of HashBase.

### 6. Multiple Inheritance
The `@` prefix naturally supports multiple inheritance (e.g., `use Object::HashBase qw/@P1 @P2/`). The existing "might explode badly" warning for MI in the POD remains relevant for `add_pre_init`/`add_post_init` but the `@` prefix makes MI more accessible.

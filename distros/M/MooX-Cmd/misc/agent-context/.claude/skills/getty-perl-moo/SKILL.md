---
name: getty-perl-moo
description: "Use when writing classes or roles in a Moo distribution — `use Moo`, `use Moo::Role`, attributes, roles, delegation, lifecycle."
---

# Perl/Moo — House Rules and Patterns

Inheritance sparingly (stable "is-a" contracts), roles heavily — when in doubt, a role.
Base rules: `getty-perl-core`.

## House conventions

- **File order:** `use Moo;` → the other `use` lines → `use namespace::clean;` → `extends` / `with` → `has`. Exception: when a role `requires` an accessor that a `has` generates, that `has` goes above the `with` — `requires` is checked the moment `with` runs.
- **`use namespace::clean;` in every class**, after the imports it should sweep. Not in roles: a role loads its imports *before* `use Moo::Role` — anything imported after it is composed into consumers as a method. (`namespace::autoclean` before 0.16 inflates Moo classes to Moose.)
- **`is => 'ro'` is the default**; `rw` needs a reason.
- **`is => 'lazy'` + a separate `sub _build_x`** for anything non-trivial; never `default => sub {...}`. A builder that ignores `$self` is one line: `sub _build_readonly { 0 }`.
- **Reference defaults are coderefs:** `default => sub { [] }` — `default => []` is shared state.
- **`init_arg => undef`** for attributes the constructor must not set; `init_arg => 'other'` to rename or free up a method name.
- **Array/hash helper methods: `Sub::HandlesVia`, never `MooX::HandlesVia`** — the latter documents that triggers/coercions don't fire on delegated mutations. Load it after `use Moo`.
- **Types:** whether and where to type is `getty-perl-typing`'s call. A `Type::Tiny` constraint is a coderef, so `isa => Str` from `Types::Standard` plugs straight into Moo.

## Inheritance

```perl
extends 'App::Base';                            # one call: extends 'A', 'B' — a second extends REPLACES
has '+prefix' => ( default => sub { 'Hi' } );   # override an inherited attribute
```

Multiple inheritance is a last resort (`mro 'c3'`).

## Roles

```perl
package App::Role::CanDescribe;
use Moo::Role;
requires 'id';                                  # checked at composition — missing id dies loud
sub describe { 'id='.$_[0]->id }

package App::Thing;
use Moo;
with 'App::Role::HasId', 'App::Role::CanDescribe';   # no "is-a"? roles only, no base class
```

- **Conflicts:** one `with 'RoleA', 'RoleB';` where both define `foo` dies; separate `with` lines → the first role silently wins; a `foo` defined in the class beats both. Fix by refactoring the overlap.
- **Parameterized roles:** `MooX::Role::Parameterized` (experimental). The `role { }` block runs at composition; `$mop` proxies `has`/`method`/`around`/`before`/`after`/`requires`:

```perl
package Counter;
use Moo::Role;
use MooX::Role::Parameterized;
parameter name => ( is => 'ro', required => 1 );
role {
  my ( $p, $mop ) = @_;
  my $n = $p->name;
  $mop->has( $n => ( is => 'rw', default => sub { 0 } ) );
  $mop->method( "inc_$n" => sub { $_[0]->$n( $_[0]->$n + 1 ) } );
};

package Thing;
use Moo;
use MooX::Role::Parameterized::With;
with Counter => { name => 'hits' };             # hits attribute + inc_hits method
```

## Delegation

```perl
package Kitchen;
use Moo;
use Sub::HandlesVia;                            # after use Moo
use namespace::clean;

has counter => ( is => 'ro', required => 1, handles => 'App::Role::CounterAPI' );
# or handles => [qw( inc reset )], or handles => { add => 'push' }

has food => (
  is          => 'ro',
  default     => sub { [] },
  handles_via => 'Array',
  handles     => { add => 'push', find => 'grep' },
);
```

`handles` does not run `isa`/`coerce`/`trigger` on the delegate itself.

## Modifiers and triggers

```perl
before calc => sub { croak 'x<0' if $_[1] < 0 };   # validate; cannot change the return
around calc => sub {
  my ( $orig, $self, @args ) = @_;
  return $self->$orig(@args) + 1;                 # only around can change the return
};
after calc => sub { ... };                        # side effects, logging
```

- Modifiers from several roles stack in composition order; `around` must forward `@_`.
- **`trigger => 1`** calls `_trigger_<name>`; it fires on `new()` and set, not on `default`/`builder`, and gets **no old value** (unlike Moose).

## Lifecycle

```perl
around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  return { source => $args[0] } if @args == 1 && !ref $args[0];   # normalize
  return $class->$orig(@args);
};

sub FOREIGNBUILDARGS {          # args for a non-Moo parent's constructor
  my ( $class, $args ) = @_;
  return ( $args->{source} );
}

sub BUILD {                     # after all attributes are set; parent→child
  my ( $self, $args ) = @_;
  croak 'invalid' unless length $args->{source};
}
```

Never call `SUPER::BUILD` — Moo runs the chain. Cleanup in `DEMOLISH` (child→parent); never override `DESTROY`.

**Strict constructor:** `use MooX::StrictConstructor;` dies on unknown args (`colour => 'blue'`). `namespace::clean` can sweep its `new` — protect with `-except => ['new']` or fix the import order per the module docs.

## House-style import module

Cross-project boilerplate goes into one `Import::Into` module:

```perl
package My::Mooish;
use Import::Into;
sub import {
  my $target = caller;
  strict->import::into($target);
  warnings->import::into($target);
  Moo->import::into($target);
  namespace::clean->import::into($target);   # after Moo, cleans stray imports
}
```

Order matters: imports → `Moo` → `namespace::clean`. With Moo 2, `strictures` v2.

## Moose interop

Moose loaded before the Moo classes compile (`BEGIN { require Moose }`) → Moo inflates its metaclasses: a Moose class can `extends` a Moo class, a Moo class can `with` a Moose role. Moose-style syntax in Moo (`isa => 'Str'`, `lazy_build`): `MooX::late`. Never `Any::Moose` (deprecated).

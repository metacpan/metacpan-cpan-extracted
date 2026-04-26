---
name: perl-core
description: Getty's house rules for all Perl code — module loading, Moose patterns, cpanfile versioning for Getty-authored CPAN distributions, stylistic choices that differ from defaults. Load on any Perl edit in a Getty project.
---

# Perl Core — Getty House Rules

These rules override defaults. They are non-negotiable in Getty projects.

## Module loading

- **`use Module;` at the top.** Always. Every dependency is loaded at compile time.
- **`require` is forbidden as a "lazy optimization".** Never use it to shave startup. If you find yourself writing `require Foo;` inside a method body, stop. Move it to a top-level `use`.
- **`require` is allowed ONLY for true runtime plugin loading** — i.e. the class to load is determined from config/DB at runtime (e.g. `Module::Runtime::use_module($class_from_db)`). If the class name is known at write-time, `use` it.
- **`require` + `->new` directly in a controller action** is a red flag. Fix by hoisting to `use` at the top of the file.

## Singletons

- **`->instance`** for classes that use `MooseX::Singleton` or `MooX::Singleton`. Never call `->new` on a singleton.
- **`->new`** for everything else.

## Getty CPAN distributions — cpanfile versioning

Getty's dist.ini uses `[@Author::GETTY]`, which sets `$VERSION` in the repo to the **next, unreleased** version (e.g. `0.402` while CPAN is at `0.401`). The repo is ALWAYS ahead of CPAN by one.

**Rules:**

1. **NEVER copy a version number from a Getty-authored repo into a `cpanfile`.** The repo version is not released. `cpanm` cannot install it. Your build will break.
2. **Check `cpanm --info Module::Name`** (or CPAN / MetaCPAN) to get the actual released version.
3. **Every Getty-authored distribution listed in our project cpanfiles must be pinned to the latest released version on CPAN.** Not `'0'`, not some stale number — the current latest. Check with `cpanm --info` before writing the requires line.
4. **Re-check on upgrade.** When bumping, use `cpanm --info` again.

Getty-authored examples (non-exhaustive): `Langertha`, `IO::K8s`, `Kubernetes::REST`, `WWW::Firecrawl`, `Net::Async::Firecrawl`, `Net::Async::WebSearch`, `Catalyst::Plugin::ChainedURI`, `Locale::Simple`, `DBIO::*`, `WWW::Zitadel`, `WWW::PayPal`, `WWW::Chain`.

Quick check for unknown modules:

```bash
cpanm --info Module::Name | tail -1
# → GETTY/Module-Name-1.234.tar.gz  ← pin to 1.234
```

## Moose / OOP style

- **`lazy_build => 1` + `sub _build_foo`** is strongly preferred over `default => sub { ... }` for anything non-trivial. Keeps attribute declarations clean.
- **`weak_ref => 1`** on attributes that hold a reference back to a parent/owner object. Standard for nested Moose object graphs — prevents circular refs.
- **`namespace::autoclean`** on every class file. For classes that extend DBIx::Class (`MooseX::NonMoose` pattern), use **`MooseX::MarkAsMethods autoclean => 1`** instead.
- **`no Moose;` + `__PACKAGE__->meta->make_immutable;`** at the bottom of every Moose class.
- **`my ( $self ) = @_;`** — explicit destructure, not `my $self = shift;`. Space inside the parens.
- **Explicit import lists with `qw( ... )`** — `use Foo qw( bar baz );`. Never rely on default exports unless they're documented as stable.

### Methods, not bare subs

- **In a Moose class, every helper is a method on `$self`.** Not a bare `sub _foo { ... }` invoked as `_foo($self->goldmine, $x)`. The class is there; use it.
- **Per-process caches go on the singleton as a Moose attribute** (`has _cache => ( is => 'ro', default => sub { {} } )`), not a `my %CACHE` package variable. Survives test isolation, lets a future caller swap state per instance.
- **No package-level state** unless it's a true global (an `%ENGINE_CLASS` lookup table that's literally constant counts; a per-call cache does not).
- Bare subs are OK in **non-class utility modules** that are imported as functions (`Goldmine::I18n::gm_key`, `Goldmine::BlockerReason::blocker`). Once a file says `use Moose` / `use MooseX::Singleton`, every `sub` should be a method.

Why: bare subs hide what the call needs (`$gm` passed manually each time), can't be overridden in a subclass, can't be mocked in tests, and force every caller to thread state by hand. `$self->method` is one extra colon-pair and gives all four for free.

## Style / whitespace

- **2-space indentation.** Not 4. Not tabs. Every Getty Perl file.
- **No trailing commas** at the end of multi-line lists (different from Python convention).

## File I/O

- **`Path::Tiny`** for every file operation. Not `File::Spec`, not bare `open`. Method-chain: `path(...)->child(...)->slurp_utf8`.

## JSON

- **`JSON::MaybeXS`** always. When encoding, set `canonical => 1, convert_blessed => 1` on the encoder object.

## DBIC-ish result classes

- Column defs via **`DBIx::Class::Candy`** or **`DBIO::Candy`** — use `primary_column` / `column` macros, not `__PACKAGE__->add_column(...)`.
- **`keep_storage_value => 1`** on enum and integer columns that shouldn't be inflated/deflated.
- **`\'NOW()'`** (literal scalar ref) for DB-side timestamp defaults.

## Forbidden / anti-patterns

- ❌ `require Foo` inside a method to "speed up startup"
- ❌ Using `$VERSION` from a Getty repo as the cpanfile requirement
- ❌ `default => sub { ... }` for a non-trivial Moose attribute default (use `lazy_build`)
- ❌ 4-space indent in new Perl files
- ❌ `File::Spec` in new code
- ❌ `Data::Dumper` in shipped code (use `DDP` / `Data::Printer` for debug, strip before commit)

## When in doubt

Grep an existing Getty project (`~/dev/perl/ellis/edge/`, `~/dev/perl/langertha/`, `~/dev/perl/shore/`) for how the pattern is used there. That is the ground truth.

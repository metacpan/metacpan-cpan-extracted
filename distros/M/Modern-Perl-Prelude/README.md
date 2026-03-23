# Modern::Perl::Prelude

[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](https://dev.perl.org/licenses/)
[![Perl](https://img.shields.io/badge/perl-5.30%2B-blue.svg)](https://www.perl.org/)
[![CI](https://github.com/neo1ite/Modern-Perl-Prelude/actions/workflows/ci.yml/badge.svg)](https://github.com/neo1ite/Modern-Perl-Prelude/actions/workflows/ci.yml)

A small lexical prelude for writing modern-style Perl on Perl 5.30+.

## What it enables by default

- `strict`
- `warnings`
- `feature qw(say state fc)`
- `Feature::Compat::Try`
- selected functions from `builtin::compat`

Default imported functions/features:

- `say`
- `state`
- `fc`
- `try` / `catch`
- `blessed`
- `refaddr`
- `reftype`
- `trim`
- `ceil`
- `floor`
- `true`
- `false`
- `weaken`
- `unweaken`
- `is_weak`

## Optional imports

### Flag-style

Supported flags:

- `-utf8`
- `-class`
- `-defer`
- `-corinna`
- `-always_true`

Examples:

```perl
use Modern::Perl::Prelude '-utf8';

use Modern::Perl::Prelude qw(
    -class
    -defer
);

use Modern::Perl::Prelude qw(
    -class
    -utf8
    -always_true
);
```
### Hash-style

Hash-style arguments are supported as a **single hash reference**:

```perl
use Modern::Perl::Prelude {
    utf8        => 1,
    defer       => 1,
    always_true => 1,
};
```

Supported hash keys:

* `utf8`
* `class`
* `defer`
* `corinna`
* `always_true`

For compatibility-layer options (`class`, `defer`, `corinna`), a true scalar enables the option. A hash reference also enables it and is passed through to the underlying module's `import`.

For `always_true`, use a boolean value.

### `-utf8` / `utf8`

Enables source-level UTF-8, like:

```perl
use Modern::Perl::Prelude '-utf8';
```

or:

```perl
use Modern::Perl::Prelude {
    utf8 => 1,
};
```

### `-class` / `class`

Enables `Feature::Compat::Class` on demand:

```perl
use Modern::Perl::Prelude '-class';

class Point {
    field $x :param = 0;
    field $y :param = 0;

    method sum {
        return $x + $y;
    }
}
```

### `-defer` / `defer`

Enables `Feature::Compat::Defer` on demand:

```perl
use Modern::Perl::Prelude '-defer';

{
    defer { warn "leaving scope\n" };
    ...
}
```

### `-corinna` / `corinna`

Enables direct `Object::Pad` / Corinna-like syntax on demand:

```perl
use Modern::Perl::Prelude '-corinna';

class Person {
    field $name :param;
    field $age  :param = 0;

    method greet {
        return "Hello, I'm $name and I'm $age years old";
    }
}
```

Hash-style example:

```perl
use Modern::Perl::Prelude {
    corinna => {},
    utf8    => 1,
};
```

### `-always_true` / `always_true`

Enables automatic true return for the currently-compiling file, so a module can omit the trailing:

```perl
1;
```

Example module without `1;`:

```perl
use Modern::Perl::Prelude qw(
    -class
    -utf8
    -always_true
);

class My::App::Person {
    field $name :param;
    field $age  :param = 0;

    method greet {
        return "Hello, I'm $name and I'm $age years old";
    }
}
```

Hash-style example:

```perl
use Modern::Perl::Prelude {
    class       => 1,
    utf8        => 1,
    always_true => 1,
};

class My::App::Person {
    field $name :param;
}
```

### Option compatibility rules

Any non-conflicting combination is allowed.

`-class` and `-corinna` are intentionally mutually exclusive.

The same rule applies to hash-style arguments:

```perl
use Modern::Perl::Prelude {
    class   => 1,
    corinna => 1,
}; # dies
```

## Usage

Basic usage:

```perl
use Modern::Perl::Prelude;

state $counter = 0;

my $s = trim("  hello  ");
my $folded = fc("Straße");

try {
    die "boom\n";
}
catch ($e) {
    warn $e;
}
```

With `Feature::Compat::Class`:

```perl
use Modern::Perl::Prelude qw(
    -class
    -defer
);

class Example {
    field $value :param = 0;

    method value {
        return $value;
    }
}

{
    defer { warn "scope ended\n" };
    my $obj = Example->new(value => 42);
    say $obj->value;
}
```

With `Object::Pad`:

```perl
use Modern::Perl::Prelude {
    corinna => {},
    utf8    => 1,
};

class Person {
    field $name :param;
    field $age  :param = 0;

    method greet {
        return "Hello, I'm $name and I'm $age years old";
    }
}

my $p = Person->new(name => 'José');
say $p->greet;
```

With always_true for a module file:

```perl
use Modern::Perl::Prelude qw(
    -class
    -utf8
    -always_true
);

class My::App::Person {
    field $name :param;
}

# no trailing 1;
```

## Lexical disabling

You can disable native pragmata/features lexically again:

```perl
no Modern::Perl::Prelude;
```

This reliably disables native pragmata/features managed directly by the module, such as:

* `strict`
* `warnings`
* `say`
* `state`
* `fc`
* `utf8`

Compatibility layers are treated as import-only for cross-version use on Perl 5.30+, so they are not guaranteed to be symmetrically undone by:

```perl
no Modern::Perl::Prelude;
```

This applies to:

* `Feature::Compat::Try`
* `Feature::Compat::Class`
* `Feature::Compat::Defer`
* `Object::Pad`
* `builtin::compat`

`always_true` is different: it is file-scoped, and you can explicitly disable it for the current file with:

```perl
no Modern::Perl::Prelude '-always_true';
```

or:

```perl
no Modern::Perl::Prelude { always_true => 1 };
```

## Design goals

This module is intended as a small project prelude for codebases that want a more modern Perl style while keeping runtime compatibility with Perl 5.30+.

It is implemented as a lexical wrapper using `Import::Into`, so pragmata and lexical features affect the caller's scope rather than the wrapper module itself.

Optional compatibility layers are loaded lazily and only when explicitly requested.

`always_true` is implemented via the CPAN module `true` and is file-scoped rather than lexically-scoped.

## Install

Using `MakeMaker`:

```shell
perl Makefile.PL
make
make test
make install
```

Using `cpanm` for dependencies:

```shell
cpanm --installdeps .
```

Including author/develop dependencies:

```shell
cpanm --with-develop --installdeps .
```

## Test

Run normal tests:

```shell
make test
```

Run author tests:

```shell
prove -lv xt/author
```

Run coverage:

```shell
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t xt/author
cover
```

## Current status

* Normal test suite: passing
* Author tests: passing
* POD coverage: passing
* Devel::Cover coverage: 100%

## Authors

* Sergey Kovalev <skov@cpan.org>
* Kirill Dmitriev <zaika.k1007@gmail.com>

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

---

## `Changes`

```text
Revision history for Modern::Perl::Prelude

0.008  2026-03-22
    - Add optional -always_true / always_true support via the true module
    - Allow modules to omit a trailing 1; on Perl 5.30+ when always_true is enabled
    - Support both flag-style and hash-style always_true imports
    - Support explicit no Modern::Perl::Prelude -always_true / { always_true => 1 }
    - Add true as a dependency and use true::VERSION in Makefile metadata
    - Document always_true in POD and README
    - Add coverage tests for always_true import and unimport behavior
    - Preserve 0.007 work on hash-style imports and Test2::Tools::Spec conversion

0.007  2026-03-22
    - Add documented hash-style import arguments via a single hash reference
    - Support hash-style keys: utf8, class, defer, corinna
    - Make -class and -corinna mutually exclusive for both flag-style and hash-style imports
    - Add tests for hash-style utf8 import and hash-style corinna import
    - Add tests for unknown hash-style keys and mixed flag/hash argument misuse
    - Update README and POD to document hash-style imports and class/corinna exclusivity
    - Keep Object::Pad as the test dependency for corinna support
    - Convert t/04-class-defer.t to Test2::Tools::Spec
    - Convert t/05-corinna.t to Test2::Tools::Spec
    - Replace Test2::Bundle::Extended test dependency with Test2::V0 and Test2::Tools::Spec
    - Fix CI failures on Perl 5.30 .. 5.38 caused by missing Test2 bundle
    - Add co-author metadata and documentation

0.006  2026-03-22
    - Add optional -corinna import via Object::Pad
    - Make -class and -corinna mutually exclusive
    - Add t/05-corinna.t with Object::Pad coverage
    - Add Object::Pad to test dependencies
    - Refresh README to document -corinna correctly
    - Add t/05-corinna.t to MANIFEST and author EOL checks

0.005  2026-03-17
    - Add optional -class import via Feature::Compat::Class
    - Add optional -defer import via Feature::Compat::Defer
    - Keep new compat layers lazy-loaded so existing default import behavior stays unchanged
    - Add t/04-class-defer.t to cover optional compat imports
    - Update packaging metadata and author EOL coverage for new test file
    - Add author and git information

0.004  2026-03-17
    - Add argument handling tests in t/03-args.t
    - Reach 100% statement, branch, subroutine and total coverage
    - Fix UTF-8 option tests to match real lexical behavior
    - Silence once-only package variable warning in args test
    - Finalize test suite for use/no and option validation paths

0.003  2026-03-17
    - Make unimport honest: only undo native pragmata/features
    - Fix no.t to test only reliably reversible native features
    - Clarify POD about import-only compat layers

0.002  2026-03-17
    - Add unimport support: no Modern::Perl::Prelude
    - Add author tests
    - Add GitHub Actions CI matrix for Perl 5.30 .. 5.42
    - Add cpanfile
    - Refresh distribution skeleton

0.001  2026-03-17
    - First version
```

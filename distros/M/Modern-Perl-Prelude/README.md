# Modern::Perl::Prelude

[![License](https://img.shields.io/badge/license-Perl%205-blue.svg)](https://dev.perl.org/licenses/)
[![Perl](https://img.shields.io/badge/perl-5.30%2B-blue.svg)](https://www.perl.org/)
[![CI](https://github.com/neo1ite/Modern-Perl-Prelude/actions/workflows/ci.yml/badge.svg)](https://github.com/neo1ite/Modern-Perl-Prelude/actions/workflows/ci.yml)

A small lexical prelude for writing modern-style Perl on Perl 5.26+.

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

- `utf8`
- `class`
- `defer`
- `corinna`
- `always_true`

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

## Option compatibility rules

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

With `always_true` for a module file:

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

- `strict`
- `warnings`
- `say`
- `state`
- `fc`
- `utf8`

Compatibility layers are treated as import-only for cross-version use on Perl 5.30+, so they are not guaranteed to be symmetrically undone by:

```perl
no Modern::Perl::Prelude;
```

This applies to:

- `Feature::Compat::Try`
- `Feature::Compat::Class`
- `Feature::Compat::Defer`
- `Object::Pad`
- `builtin::compat`

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

- Normal test suite: passing
- Author tests: passing
- POD coverage: passing
- Devel::Cover coverage: 100%

## Authors

- Sergey Kovalev <skov@cpan.org>
- Kirill Dmitriev <zaika.k1007@gmail.com>

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

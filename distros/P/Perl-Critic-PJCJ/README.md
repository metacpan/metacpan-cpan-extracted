# Perl::Critic::PJCJ

A Perl::Critic policy distribution for enforcing code style consistency
in Perl code.

## Description

This distribution provides Perl::Critic policies that enforce consistent
coding practices to improve code readability and maintainability. It includes
policies for string quoting consistency and line length limits.

## Policies

### Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting

This policy enforces consistent and optimal quoting practices through three
simple rules:

1. **Reduce punctuation** - Prefer fewer escaped characters. Prefer real quotes
   over quote-like operators when possible.

2. **Prefer interpolated strings** - If it doesn't matter whether a string is
   interpolated or not, prefer the interpolated version (double quotes).

3. **Use bracket delimiters in preference order** - If the best choice is a
   quote-like operator, prefer `()`, `[]`, `<>`, or `{}` in that order.

**Special Cases:**

- **Use statements** - Import lists require `qw()` for multiple arguments
- **Newlines** - Multi-line strings may use any quoting style

#### Rationale

- Minimising escape characters improves readability and reduces errors
- Simple quotes are preferred over their `q()` and `qq()` equivalents when
  possible
- Double quotes are preferred for consistency and to allow potential
  interpolation
- Many years ago, Tom Christiansen wrote a lengthy article on how perl's default
  quoting system is interpolation, and not interpolating means something
  extraordinary is happening. I can't find the original article, but you can
  see that double quotes are used by default in The Perl Cookbook, for example.
- Only bracket delimiters should be used (no exotic delimiters like `/`,
  `|`, `#`, etc.)
- Optimal delimiter selection reduces visual noise in code

#### Examples

**Bad examples:**

```perl
# Excessive punctuation
my $greeting = 'hello';                     # use double quotes (Rule 2)
my @words    = qw{word(with)parens};        # use qw[] (Rules 1, 3)
my $file     = q!path/to/file!;             # use "" (Rules 1, 3)
my $text     = qq(simple);                  # use "" instead of qq() (Rule 1)
my $literal  = q(contains$literal);         # use '' instead of q() (Rule 1)
```

**Good examples:**

```perl
# Rule 1: Reduce punctuation
my $greeting = "hello";                     # double quotes for simple strings
my $text     = "simple";                    # "" preferred over qq()
my $literal  = 'contains$literal';          # '' preferred over q()
my $file     = "path/to/file";              # "" reduces punctuation

# Rule 2: Prefer interpolated strings
my $email = 'user@domain.com';              # literal @ uses single quotes
my $var   = 'Price: $10';                   # literal $ uses single quotes

# Rule 3: Optimal delimiter selection
my @words = qw[ word(with)parens ];         # [] handles unbalanced parentheses
my $cmd   = qx( command[with]brackets );    # () handles unbalanced brackets
my @list  = qw( one two );                  # bracket delimiters only

# Special Case: Use statements
use Foo;                                    # no arguments allowed
use Bar ();                                 # empty parentheses allowed
use Baz "single_arg";                       # single arg with double quotes
use Qux qw( single_arg );                   # single arg with qw()
use Quux qw( arg1 arg2 arg3 );              # multiple args with qw() only

# Special Case: Strings with newlines
my $text = qq(                              # Any quoting style is allowed
  line 1                                    # for multi-line strings
  line 2
);
```

### Perl::Critic::Policy::CodeLayout::ProhibitLongLines

This policy enforces a configurable maximum line length to improve code
readability, especially in narrow terminal windows or when viewing code
side-by-side with diffs or other files.

The default maximum line length is 80 characters, which provides good
readability across various display contexts while still allowing reasonable
code density.

You can configure `perltidy` to keep lines within the specified limit. Only
when it is unable to do that will you need to manually make changes.

#### Configuration

- **max_line_length** - Maximum allowed line length in characters (default: 80)

#### Examples

**Bad examples (exceeds 72 characters):**

```perl
# Line exceeds configured maximum
my $very_long_variable_name = "long string that exceeds maximum length";

# Long variable assignment
my $configuration_manager = VeryLongModuleName::ConfigurationManager->new;

# Long method call
$object->some_very_very_long_method_name($param1, $param2, $param3, $param4);

# Long string literal
my $error_message =
  "This is a very long error message that exceeds the configured maximum";
```

**Good examples:**

```perl
# Line within limit
my $very_long_variable_name =
  "long string that exceeds maximum length";

# Broken into multiple lines
my $configuration_manager =
  VeryLongModuleName::ConfigurationManager->new;

# Parameters on separate lines
$object->some_very_very_long_method_name(
  $param1, $param2, $param3, $param4
);

# Use concatenation
my $error_message = "This is a very long error message that " .
  "exceeds the configured maximum";
```

#### Usage

Add to your `.perlcriticrc` file:

```ini
[CodeLayout::ProhibitLongLines]
max_line_length = 72
```

Or use the default 80 character limit:

```ini
[CodeLayout::ProhibitLongLines]
```

## Installation

To install this module, run the following commands:

```bash
cpan Perl::Critic::PJCJ
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

## Usage

Add individual policies to your `.perlcriticrc` file:

```ini
[ValuesAndExpressions::RequireConsistentQuoting]

[CodeLayout::ProhibitLongLines]
max_line_length = 72
```

Or include the entire distribution:

```ini
include = Perl::Critic::PJCJ
```

Then run perlcritic on your code:

```bash
# Run individual policies
perlcritic --single-policy \
  ValuesAndExpressions::RequireConsistentQuoting MyScript.pl

perlcritic --single-policy \
  CodeLayout::ProhibitLongLines MyScript.pl

# Or run all policies from the distribution
perlcritic --include Perl::Critic::PJCJ MyScript.pl
```

## Development

This module is built using Dist::Zilla. To build and test:

```bash
dzil test
dzil build
```

### Additional Development Targets

The generated Makefile includes additional development targets:

```bash
# Format code with perltidy
make format

# Run linting with perlcritic
make lint

# Generate test coverage reports
make cover
make cover-html
make cover-compilation
```

These targets are automatically available after running `perl Makefile.PL`.

## Author

Paul Johnson <paul@pjcj.net>

## Copyright and Licence

Copyright 2025 Paul Johnson.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

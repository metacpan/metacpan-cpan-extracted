[![Actions Status](https://github.com/kfly8/Syntax-Keyword-Assert/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Syntax-Keyword-Assert/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Syntax-Keyword-Assert/main.svg?style=flat)](https://coveralls.io/r/kfly8/Syntax-Keyword-Assert?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Syntax-Keyword-Assert.svg)](https://metacpan.org/release/Syntax-Keyword-Assert)
# NAME

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost in production

# SYNOPSIS

```perl
use Syntax::Keyword::Assert;

sub hello($name) {
    assert { defined $name };
    say "Hello, $name!";
}

hello("Alice"); # => Hello, Alice!
hello();        # => Dies when STRICT mode is enabled
```

# DESCRIPTION

Syntax::Keyword::Assert introduces a lightweight assert keyword to Perl, designed to provide runtime assertions with minimal overhead.

- **STRICT Mode**

    When STRICT mode is enabled, assert statements are checked at runtime. If the assertion fails (i.e., the block returns false), the program dies with an error. This is particularly useful for catching errors during development or testing.

- **Zero Runtime Cost**

    When STRICT mode is disabled, the assert blocks are completely ignored at compile phase, resulting in zero runtime cost. This makes Syntax::Keyword::Assert ideal for use in production environments, as it does not introduce any performance penalties when assertions are not needed.

- **Simple Syntax**

    The syntax is straightforward—assert BLOCK—making it easy to integrate into existing code.

## STRICT Mode Control

The behavior of STRICT mode is controlled by the [Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode) module. You can enable or disable STRICT mode depending on your environment (e.g., development, testing, production).

For example, to enable STRICT mode:

```perl
BEGIN { $ENV{PERL_STRICT} = 1 }  # Enable STRICT mode

use Syntax::Keyword::Assert;
use Devel::StrictMode;

assert { 1 == 1 };  # Always passes
assert { 0 == 1 };  # Dies if STRICT mode is enabled
```

To disable STRICT mode (it is disabled by default):

```perl
use Syntax::Keyword::Assert;
use Devel::StrictMode;

assert { 0 == 1 };  # Block is ignored, no runtime cost
```

SEE ALSO:
[Bench ](https://metacpan.org/pod/%20https%3A#github.com-kfly8-Syntax-Keyword-Assert-blob-main-bench-compare-no-assertion.pl)

# TIPS

## Verbose error messages

If you set `$Carp::Verbose = 1`, you can see stack traces when an assertion fails.

```perl
use Syntax::Keyword::Assert;
use Carp;

assert {
    local $Carp::Verbose = 1;
    0;
}
```

# SEE ALSO

- [PerlX::Assert](https://metacpan.org/pod/PerlX%3A%3AAssert)

    This module also uses keyword plugin, but it depends on [Keyword::Simple](https://metacpan.org/pod/Keyword%3A%3ASimple).

- [Devel::Assert](https://metacpan.org/pod/Devel%3A%3AAssert)

    This module provides a similar functionality, but it dose not use a keyword plugin.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>

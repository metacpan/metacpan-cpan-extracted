[![Actions Status](https://github.com/kfly8/Syntax-Keyword-Assert/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Syntax-Keyword-Assert/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Syntax-Keyword-Assert/main.svg?style=flat)](https://coveralls.io/r/kfly8/Syntax-Keyword-Assert?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Syntax-Keyword-Assert.svg)](https://metacpan.org/release/Syntax-Keyword-Assert)
# NAME

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost in production

# SYNOPSIS

```perl
use Syntax::Keyword::Assert;

my $name = 'Alice';
assert( $name eq 'Bob' );
# => Assertion failed ("Alice" eq "Bob")
```

# DESCRIPTION

Syntax::Keyword::Assert introduces a lightweight assert keyword to Perl, designed to provide runtime assertions with minimal overhead.

- **STRICT Mode**

    When STRICT mode is enabled, assert statements are checked at runtime. Default is enabled. If the assertion fails (i.e., the block returns false), the program dies with an error. This is particularly useful for catching errors during development or testing.

    `$ENV{PERL_ASSERT_ENABLED}` can be used to control STRICT mode.

    ```
    BEGIN { $ENV{PERL_ASSERT_ENABLED} = 0 }  # Disable STRICT mode
    ```

- **Zero Runtime Cost**

    When STRICT mode is disabled, the assert blocks are completely ignored at compile phase, resulting in zero runtime cost. This makes Syntax::Keyword::Assert ideal for use in production environments, as it does not introduce any performance penalties when assertions are not needed.

- **Simple Syntax**

    The syntax is dead simple. Just use the assert keyword followed by a block that returns a boolean value.

    ```
    assert( $name eq 'Bob' );
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

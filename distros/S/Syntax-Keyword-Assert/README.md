[![Actions Status](https://github.com/kfly8/Syntax-Keyword-Assert/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Syntax-Keyword-Assert/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Syntax-Keyword-Assert/main.svg?style=flat)](https://coveralls.io/r/kfly8/Syntax-Keyword-Assert?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Syntax-Keyword-Assert.svg)](https://metacpan.org/release/Syntax-Keyword-Assert)
# NAME

Syntax::Keyword::Assert - assert keyword for Perl

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

This module provides a syntax plugin that introduces an **assert** keyword to Perl.
It dies when the block returns false and `STRICT` mode is enabled. When `STRICT` mode is disabled, the block is ignored at compile time. The syntax is simple, `assert BLOCK`.

`STRICT` mode is controlled by [Devel::StrictMode](https://metacpan.org/pod/Devel%3A%3AStrictMode).

# SEE ALSO

[PerlX::Assert](https://metacpan.org/pod/PerlX%3A%3AAssert), [Devel::Assert](https://metacpan.org/pod/Devel%3A%3AAssert), [Carp::Assert](https://metacpan.org/pod/Carp%3A%3AAssert)

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>

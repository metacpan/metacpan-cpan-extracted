[![Actions Status](https://github.com/kfly8/Syntax-Keyword-Assert/actions/workflows/test.yml/badge.svg)](https://github.com/kfly8/Syntax-Keyword-Assert/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Syntax-Keyword-Assert/main.svg?style=flat)](https://coveralls.io/r/kfly8/Syntax-Keyword-Assert?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Syntax-Keyword-Assert.svg)](https://metacpan.org/release/Syntax-Keyword-Assert)
# NAME

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost

# SYNOPSIS

```perl
use Syntax::Keyword::Assert;

my $obj = bless {}, "Foo";
assert($obj isa "Bar");
# => Assertion failed (Foo=HASH(0x11e022818) isa "Bar")
```

# DESCRIPTION

Syntax::Keyword::Assert provides a syntax extension for Perl that introduces a `assert` keyword.

By default assertions are enabled, but can be disabled by setting `$ENV{PERL_ASSERT_ENABLED}` to false before this module is loaded:

```
BEGIN { $ENV{PERL_ASSERT_ENABLED} = 0 }  # Disable assertions
```

When assertions are disabled, the `assert` are completely ignored at compile phase, resulting in zero runtime cost. This makes Syntax::Keyword::Assert ideal for use in production environments, as it does not introduce any performance penalties when assertions are not needed.

# KEYWORDS

## assert

```
assert(EXPR)
```

If EXPR is truthy in scalar context, then happens nothing. Otherwise, it dies with a user-friendly error message.

Here are some examples:

```perl
assert("apple" eq "banana");  # => Assertion failed ("apple" eq "banana")
assert(123 != 123);           # => Assertion failed (123 != 123)
assert(1 > 10);               # => Assertion failed (1 > 10)
```

# SEE ALSO

- [PerlX::Assert](https://metacpan.org/pod/PerlX%3A%3AAssert)

    This module also uses keyword plugin, but it depends on [Keyword::Simple](https://metacpan.org/pod/Keyword%3A%3ASimple). And this module's error message does not include the failed expression.

- [Devel::Assert](https://metacpan.org/pod/Devel%3A%3AAssert)

    This module provides a similar functionality, but it dose not use a keyword plugin.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>

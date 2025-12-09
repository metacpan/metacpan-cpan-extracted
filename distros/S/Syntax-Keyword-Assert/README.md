[![Actions Status](https://github.com/kfly8/Syntax-Keyword-Assert/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kfly8/Syntax-Keyword-Assert/actions?workflow=test) [![Coverage Status](https://img.shields.io/coveralls/kfly8/Syntax-Keyword-Assert/main.svg?style=flat)](https://coveralls.io/r/kfly8/Syntax-Keyword-Assert?branch=main) [![MetaCPAN Release](https://badge.fury.io/pl/Syntax-Keyword-Assert.svg)](https://metacpan.org/release/Syntax-Keyword-Assert)
# NAME

Syntax::Keyword::Assert - assert keyword for Perl with zero runtime cost

# SYNOPSIS

```perl
use Syntax::Keyword::Assert;

my $obj = bless {}, "Foo";
assert($obj isa "Bar");
# => Assertion failed (Foo=HASH(0x11e022818) isa "Bar")

assert($x > 0, "x must be positive");
# => x must be positive
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
assert(EXPR, MESSAGE)
```

If EXPR is truthy in scalar context, then happens nothing. Otherwise, it dies with a user-friendly error message.

Here are some examples:

```perl
assert("apple" eq "banana");  # => Assertion failed ("apple" eq "banana")
assert(123 != 123);           # => Assertion failed (123 != 123)
assert(1 > 10);               # => Assertion failed (1 > 10)
```

You can provide a custom error message as the second argument:

```perl
assert($x > 0, "x must be positive");
# => x must be positive
```

The message expression is lazily evaluated. It is only evaluated when the assertion fails.
This is equivalent to:

```
$cond || do { die $msg }
```

This means you can use expensive computations or side effects in the message without worrying about performance when the assertion passes:

```
assert($x > 0, expensive_debug_info());
# expensive_debug_info() is NOT called if $x > 0
```

# SEE ALSO

- [PerlX::Assert](https://metacpan.org/pod/PerlX%3A%3AAssert)

    This module also uses keyword plugin, but it depends on [Keyword::Simple](https://metacpan.org/pod/Keyword%3A%3ASimple). And this module's error message does not include the failed expression.

- [Devel::Assert](https://metacpan.org/pod/Devel%3A%3AAssert)

    This module provides a similar functionality, but it does not use a keyword plugin.

# LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kobaken <kentafly88@gmail.com>

[![Actions Status](https://github.com/kfly8/p5-Sub-WrapInType-Attribute/workflows/test/badge.svg)](https://github.com/kfly8/p5-Sub-WrapInType-Attribute/actions) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Sub-WrapInType-Attribute/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Sub-WrapInType-Attribute?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Sub-WrapInType-Attribute.svg)](https://metacpan.org/release/Sub-WrapInType-Attribute)
# NAME

Sub::WrapInType::Attribute - attribute for Sub::WrapInType

# SYNOPSIS

```perl
use Sub::WrapInType::Attribute;
use Types::Standard -types;

sub hello :WrapSub([Str] => Str) {
    my $message = shift;
    return "HELLO $message";
}

hello('world!!'); # => HELLO world!!
my $code = \&hello; # => Sub::WrapInType object
```

# DESCRIPTION

This module provides attribute for Sub::WrapInType, which makes it easier to check during the compilation phase.

# ATTRIBUTES

## :WrapSub(\\@parameter\_types, $return\_type)

The `:WrapSub` code attribute performs `Sub::WrapInType#wrap_sub` on the subroutine that specified this attribute.

## :WrapMethod(\\@parameter\_types, $return\_type)

The `:WrapMethod` code attribute performs `Sub::WrapInType#wrap_method` on the subroutine that specified this attribute.

# SEE ALSO

[Sub::WrapInType](https://metacpan.org/pod/Sub%3A%3AWrapInType)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>

# NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr - Check for "return $x or ..."

# DESCRIPTION

`return` when encountered in an expression returns from the enclosing
subroutine, without evaluating the rest of the expression. So a
lower-precedence operator (`or`, `and`, `xor`) won't get evaluated
after a `return`. This most commonly appears as the mis-idiom:

    # NO! DON'T DO THIS!
    return $x or die 'Aaaagh! $x was zero!';

Instead, use the higher-precedence `||` operator, like  this:

    return $x || die 'Aaaagh! $x was zero!';

Or separate the two operations, like this:

    $x or die 'Aaaagh! $x was zero!';
    return $x;

# CONFIGURATION

This Policy is not configurable except for the standard options.

# LICENSE

Copyright (C) 2016 Jeremy Leader.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jeremy Leader <jeremy@ziprecruiter.com>

# SEE ALSO

[Perl::Critic](https://metacpan.org/pod/Perl::Critic)

# NAME

Perl::Critic::Policy::ControlStructures::ProhibitReturnInMappingBlock - Do not "return" in mapping blocks (map, grep)

# AFFILIATION

This policy is part of the [Perl::Critic::Policy::ControlStructures::ProhibitReturnInMappingBlock](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3AControlStructures%3A%3AProhibitReturnInMappingBlock) distribution.

# DESCRIPTION

Using `return` in a mapping block (`map` or `grep`) causes unexpected behavior.
A `return` exits the entire enclosing subroutine, not just the block.

    sub func {
        my @list = (1, 2, 3);
        my @result = map {
            return 0 unless $_; # not ok
            $_ + 5;
        } @list;
        return @result;
    }

If you want to skip an element, use `next` instead:

    sub func {
        my @list = (1, 2, 3);
        my @result = map {
            next unless $_;
            $_ + 5;
        } @list;
        return @result;
    }

This applies equally to `grep` blocks.

# CONFIGURATION

This Policy is not configurable except for the standard options.

# SEE ALSO

[Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3AControlStructures%3A%3AProhibitReturnInDoBlock) by utgwkk, which inspired this policy.

# LICENSE

Copyright (C) 2026 hogashi. Portions copyright (C) 2020 utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hogashi

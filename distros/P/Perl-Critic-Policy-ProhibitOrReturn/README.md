# NAME

Perl::Critic::Policy::ProhibitOrReturn - Do not use \`or return\`

# AFFILIATION

This policy is a policy in the [Perl::Critic::Policy::ProhibitOrReturn](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3AProhibitOrReturn) distribution.

# DESCRIPTION

Avoid using `or return`. Consider using equivalent `if` (or `unless`) statement instead.

    # not ok
    sub foo {
        my ($x) = @_;
        $x or return;
        ...
    }

    # ok
    sub foo {
        my ($x) = @_;
        return if !$x;
        ...
    }

# CONFIGURATION

This Policy is not configurable except for the standard options.

# LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

utgwkk <utagawakiki@gmail.com>

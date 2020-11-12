# NAME

Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock - Do not "return" in "do" block

# AFFILIATION

This policy is a policy in the [Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock](https://metacpan.org/pod/Perl%3A%3ACritic%3A%3APolicy%3A%3AControlStructures%3A%3AProhibitReturnInDoBlock) distribution.

# DESCRIPTION

Using `return` statement in `do` block causes unexpected behavior. A `return` returns from entire subroutine, not from `do` block.

    sub foo {
        my ($x) = @_;
        my $y = do {
            return 2 if $x < 10; # not ok
            return 3 if $x < 100; # not ok
            4;
        };
        return $x * $y;
    }
    print foo(5); # prints 2, not 10;

If you want to do early-return, you should move the body of `do` block to a new subroutine and call it.

    sub calc_y {
        my ($x) = @_;
        return 2 if $x < 10;
        return 3 if $x < 100;
        return 4;
    }

    sub foo {
        my ($x) = @_;
        my $y = calc_y($x);
        return $x * $y;
    }
    print foo(5); # prints 10

# CONFIGURATION

This Policy is not configurable except for the standard options.

# LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

utgwkk <utagawakiki@gmail.com>

# NAME

MouseX::Types::Enum - Object-oriented, Java-like enum type declaration based on Mouse

# SYNOPSIS

In the following example,

- Three enumeration constants, `APPLE`, `GRAPE`, and `BANANA` are defined.
- Three instance variables, `name`, `color`, `price` and `has_seed` are defined.
- A method `make_sentence($suffix)` is defined.

code:

    {
        package Fruits;

        use strict;
        use warnings;

        use Mouse;
        extends 'MouseX::Types::Enum';

        has name => (is => 'ro', isa => 'Str');
        has color => (is => 'ro', isa => 'Str');
        has price => (is => 'ro', isa => 'Num');
        has has_seed => (is => 'ro', isa => 'Int', default => 1);

        sub make_sentence {
            my ($self, $suffix) = @_;
            $suffix ||= "";
            return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
        }

        sub APPLE {1 => (
            name  => 'Apple',
            color => 'red',
            price => 1.2,
        )}
        sub GRAPE {2 => (
            name  => 'Grape',
            color => 'purple',
            price => 3.5,
        )}
        sub BANANA {3 => (
            name     => 'Banana',
            color    => 'yellow',
            has_seed => 0,
            price    => 1.5,
        )}

        __PACKAGE__->_build_enum;

        1;
    }

    # equivalence
    ok(Fruits->APPLE == Fruits->APPLE);
    ok(Fruits->APPLE != Fruits->GRAPE);
    ok(Fruits->APPLE != Fruits->BANANA);

    # instance variable
    is(Fruits->APPLE->name, 'Apple');
    is(Fruits->APPLE->color, 'red');
    is(Fruits->APPLE->price, 1.2);

    # instance method
    is(Fruits->APPLE->make_sentence('!'), 'Apple is red!');

    # get instance
    is(Fruits->get(1), Fruits->APPLE);
    is(Fruits->get(2), Fruits->GRAPE);
    is(Fruits->get(3), Fruits->BANANA);
    is_deeply(Fruits->all, {
        1 => Fruits->APPLE,
        2 => Fruits->GRAPE,
        3 => Fruits->BANANA,
    });

# DESCRIPTION

MouseX::Types::Enum provides Java-like enum type declaration based on Mouse.
You can declare enums which have instance variables and methods.

# LICENSE

Copyright (C) Naoto Ikeno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Naoto Ikeno <ikenox@gmail.com>

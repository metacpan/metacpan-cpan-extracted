# NAME

MouseX::Types::Enum - Object-oriented, Java-like enum type declaration based on Mouse

# SYNOPSIS

In the following example,

- Three enumeration constants, `APPLE`, `ORANGE`, and `BANANA` are defined.
- Three instance variables, `name`, `color`, and `has_seed` are defined.
- A method `make_sentence($suffix)` is defined.

    {
        package Fruits;

        use Mouse;
        use MouseX::Types::Enum (
            APPLE  => { name => 'Apple', color => 'red' },
            ORANGE => { name => 'Cherry', color => 'red' },
            BANANA => { name => 'Banana', color => 'yellow', has_seed => 0 }
        );

        has name => (is => 'ro', isa => 'Str');
        has color => (is => 'ro', isa => 'Str');
        has has_seed => (is => 'ro', isa => 'Int', default => 1);

        sub make_sentence {
            my ($self, $suffix) = @_;
            $suffix ||= "";
            return sprintf("%s is %s%s", $self->name, $self->color, $suffix);
        }

        __PACKAGE__->meta->make_immutable;
    }

    Fruits->APPLE == Fruits->APPLE;        # 1
    Fruits->APPLE == Fruits->ORANGE;       # ''
    Fruits->APPLE->to_string;              # 'APPLE'

    Fruits->APPLE->name;                   # 'Apple';
    Fruits->APPLE->color;                  # 'red'
    Fruits->APPLE->has_seed;               # 1

    Fruits->APPLE->make_sentence('!!!');   # 'Apple is red!!!'

    Fruits->enums; # { APPLE  => Fruits->APPLE, ORANGE => Fruits->ORANGE, BANANA => Fruits->BANANA }

If you have no need to define instance variables, you can declare enums more simply like following.

    {
        package Day;

        use MouseX::Types::Enum qw/
            Sun
            Mon
            Tue
            Wed
            Thu
            Fri
            Sat
        /;

        __PACKAGE__->meta->make_immutable;
    }

    Day->Sun == Day->Sun;   # 1
    Day->Sun == Day->Mon;   # ''
    Day->Sun->to_string;    # 'APPLE'
    Day->enums;             # { Sun => Day->Sun, Mon => Day->Mon, ... }

# DESCRIPTION

MouseX::Types::Enum provides Java-like enum type declaration.

Enums declared are

- distinguished from each other
- able to have attributes
- able to have methods

# LICENSE

Copyright (C) Naoto Ikeno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Naoto Ikeno <ikenox@gmail.com>

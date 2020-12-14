[![Build Status](https://circleci.com/gh/ybrliiu/p5-Sub-WrapInType.svg)](https://circleci.com/gh/ybrliiu/p5-Sub-WrapInType) [![Coverage Status](http://codecov.io/github/ybrliiu/p5-Sub-WrapInType/coverage.svg?branch=master)](https://codecov.io/github/ybrliiu/p5-Sub-WrapInType?branch=master)
# NAME

Sub::WrapInType - Wrap the subroutine to validate the argument type and return type.

# SYNOPSIS

    use Types::Standard -types;
    use Sub::WrapInType;

    my $sum = wrap_sub [ Int, Int ], Int, sub {
      my ($x, $y) = @_;
      $x + $y;
    };
    $sum->(2, 5);  # Returns 7
    $sum->('foo'); # Throws an exception

    my $subtract = wrap_sub [ Int, Int ], Int, sub {
      my ($x, $y) = @_;
      "$x - $y";
    };
    $subtract->(5, 2); # Returns string '5 - 2', error!

# DESCRIPTION

Sub::WrapInType is wrap the subroutine to validate the argument type and return type.

# FUNCTIONS

## wrap\_sub(\\@parameter\_types, $return\_type, $subroutine)

If you pass type constraints of parameters, a return type constraint, and a subroutine to this function,
Returns the subroutine wrapped in the process of checking the arguments given in the parameter's type constraints and checking the return value with the return value's type constraint.

    my $sum = wrap_sub [Int, Int], Int, sub {
      my ($x, $y) = @_;
      $x + $y;
    };
    $sum->(2, 5);  # Returns 7
    $sum->('foo'); # Throws an exception (Can not pass string)

    my $wrong_return_value = wrap_sub [Int, Int], Int, sub {
      my ($x, $y) = @_;
      "$x + $y";
    };
    $wrong_return_value->(2, 5); # Throws an exception (The return value isn't an Integer)
    $sum->('foo');               # Throws an exception (Can not pass string)

The type constraint expects to be passed an object of Type::Tiny.

When the subroutine returns multiple return values, it is possible to specify multiple return type constraints.

    my $multi_return_values = wrap_sub [Int, Int], [Int, Int], sub {
      my ($x, $y) = @_;
      ($x, $y);
    };
    my ($x, $y) = $multi_return_values->(0, 1);

You can pass named parameters.

    my $sub = wrap_sub(
      params => [Int, Int],
      return => Int,
      code   => sub {
        my ($x, $y) = @_;
        $x + $y;
      },
    );

If subroutine returns array or hash, Sub::WrapInType will not be able to check the type as you intended.
You should rewrite the subroutine to returns array reference or hash reference.

Sub::WrapInType does not support wantarray.

This is a wrapper for the constructor.

# METHODS

## new(\\@parameter\_types, $return\_type, $subroutine)

Constract a new Sub::WrapInType object.

    use Types::Standard -types;
    use Sub::WrapInType;
    my $wraped_sub = Sub::WrapInType->new([Int, Int] => Int, sub { $_[0] + $_[1] });

# LICENSE

Copyright (C) mp0liiu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mp0liiu <mpoliiu@cpan.org>

# SEE ALSE

[Type::Params](https://metacpan.org/pod/Type%3A%3AParams) exports the function wrap\_sub. It check only parameters type.

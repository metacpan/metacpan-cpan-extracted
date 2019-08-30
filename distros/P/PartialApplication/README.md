# NAME

PartialApplication - A small module that handle partially applying parameters to functions

# SYNOPSIS

    use PartialApplication qw( partiallyApply );

    sub concatenate {
        print join(" ", @_) . "\n";
    }

    my $greet = partiallyApply( \&concatenate, "hello" );

    $greet->("world");

# DESCRIPTION

PartialApplilcation is a small module to handle partially applying parameters.

# FUNCTIONS

## partiallyApply( \\&function, @parameters )

Partially applies the parameters to the function, giving a new function
reference.

To partially apply parameters to an object method, pass a function reference
to the method as the first parameter, the object instance as the second,
followed by the parameters to be partially applied.

    my $object = Class->new();

    my $partiallyAppliedMethod = partiallyApply( \&Class::method, $object, 1, 2, 3 );

    $partiallyAppliedMethod->(4, 5, 6);   # equivilant of $object->method(1, 2, 3, 4, 5, 6)

### RETURNS

A function reference to the partially applied function.

## partiallyApplyRight( \\&function, @parameters )

Partially applies the parameters to the end of the function call - useful for
when you're using named parameters and you want to make sure that the partially
applied parameters are the ones used.

    sub testSub {
        my %params = @_;

        print "$_ - $params{$_}\n" for keys %params;
    }

    my $partiallyAppliedFunction = partiallyApplyRight( \&testSub, asdf => 99 );

    $partiallyAppliedFunction->(asdf => 100);   # outputs: asdf - 99

### RETURNS

A function reference to the partially applied function.

## partiallyApplyN( \\&function, \\@parameterBitmap, @parameters  )

Partially applies the parameters based upon the parameterBitmap. An entry of 1 in
the parameterBitmap will use a partially applied parameter and an entry of 0
will use a parameter from the call.

    sub testSub {
        print join(", ", @_) ."\n";
    }

    my $partiallyAppliedFunction = partiallyApplyN( \&testSub, [ 1, 0, 1, 0 ], 1, 2, 3, 4, 5 );

    $partiallyAppliedFunction->('a', 'b', 'c', 'd'); # outputs: 1, a, 2, b, 3, 4, 5, c, d

This does allow you to partially apply parameter to a method call without
specifying the object instance to apply it to multiple instances.

    my $partiallyAppliedMethod2 = partiallyApplyN( \&Class::method, [ 0, 1, 1, 1 ], 1, 2, 3 );

    $partiallyAppliedMethod2->($object1, 4, 5); # equivilant to $object1->method(1, 2, 3, 4, 5)
    $partiallyAppliedMethod2->($object2, 6, 7); # equivilant to $object2->method(1, 2, 3, 6, 7)

### RETURNS

A function reference to the partially applied function.

# SEE ALSO

There's a number of other modules available that you can use for partially
applying parameters to functions (note: a number of these modules use the term
curry/currying incorrectly).

- [curry](https://metacpan.org/pod/curry)

    Partial application for object methods.

- [Sub::Curry](https://metacpan.org/pod/Sub::Curry)

    Does partial application of function in a more heavyweight/complex way.

- [Sub::DefferedPartial](https://metacpan.org/pod/Sub::DeferredPartial)

    Partial Application for named parameters (i.e. hash parameters).

- [Perl6.Currying](https://metacpan.org/pod/Perl6::Currying)

    Does Partial Application, but requires the functions to be specially prototyped.

The following Currying modules actually do proper currying of the functions and
so can be used to paritally apply parameters to a function, but they can only
be applied to functions with a fixed number of parameters.

- [Sub::Curried](https://metacpan.org/pod/Sub::Curried)

    Curries functions, and as such has has limited abilities to do Partial
    Application.

- [Attribute::Curried](https://metacpan.org/pod/Attribute::Curried)

    Lets you define a function as being curried via a attribute on the function
    definition.

# LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jason Cooper <JLCOOPER@cpan.org>

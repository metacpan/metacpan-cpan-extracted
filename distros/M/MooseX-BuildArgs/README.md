# NAME

MooseX::BuildArgs - Save the original constructor arguments for later use.

# SYNOPSIS

Create a class that uses this module:

    package MyClass;
    use Moose;
    use MooseX::BuildArgs;
    has foo => ( is=>'ro', isa=>'Str' );
    
    my $object = MyClass->new( foo => 32 );
    print $object->build_args->{foo};

# DESCRIPTION

Sometimes it is very useful to have access to the contructor arguments before builders,
defaults, and coercion take affect.  This module provides a build\_args hashref attribute
for all instances of the consuming class.  The build\_args attribute contains all arguments
that were passed to the constructor.

A contrived case for this module would be for creating a clone of an object, so you could
duplicate an object with the following code:

    my $obj1 = MyClass->new( foo => 32 );
    my $obj2 = MyClass->new( $obj1->build_args() );
    print $obj2->foo();

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

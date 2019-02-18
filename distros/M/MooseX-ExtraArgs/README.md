# NAME

MooseX::ExtraArgs - Save constructor arguments that were not consumed.

# SYNOPSIS

Create a class that uses this module:

    package MyClass;
    use Moose;
    use MooseX::ExtraArgs;
    has foo => ( is=>'ro', isa=>'Str' );
    
    my $object = MyClass->new( foo => 32, bar => 16 );
    print $object->extra_args->{bar};

# DESCRIPTION

This module provides access to any constructor arguments that were not assigned to an
attribute.  Where [MooseX::StrictConstructor](https://metacpan.org/pod/MooseX::StrictConstructor) does not allow any unknown arguments, this
module expects unknown arguments and saves them for later access.

This could be useful for proxy classes that expect extra arguments that will then be
used to pass as arguments to the underlying implementation.

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

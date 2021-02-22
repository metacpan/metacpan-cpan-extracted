# NAME

MooX::Clone - Make Moo objects clone-able

# SYNOPSIS

    package Foo;
    use Moo;
    use MooX::Clone;

    has bar => ( is => 'rw' );

    package main;

    my $foo = Foo->new( bar => 1 );
    my $bar = $foo->clone;          # deep copy of $foo

# DESCRIPTION

MooX::Clone lets you clone your Moo objects easily by adding a `clone` method. It performs a deep copy of the entire object.

# METHODS

## clone

Clone the object. See [Clone](https://metacpan.org/pod/Clone) for more details.

    my $bar = $foo->clone;

# SEE ALSO

[Clone](https://metacpan.org/pod/Clone)

# LICENSE

Copyright (C) Julien Fiegehenn.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

Julien Fiegehenn <simbabque@cpan.org>

Mohammad S Anwar <mohammad.anwar@yahoo.com>

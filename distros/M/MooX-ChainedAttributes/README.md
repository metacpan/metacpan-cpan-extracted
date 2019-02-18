# NAME

MooX::ChainedAttributes - Make your attributes chainable.

# SYNOPSIS

    package Foo;
    use Moo;
    use MooX::ChainedAttributes;
    
    has name => (
        is      => 'rw',
        chained => 1,
    );
    
    has age => (
        is => 'rw',
    );
    
    chain('age');
    
    sub who {
        my ($self) = @_;
        print "My name is " . $self->name() . "!\n";
    }
    
    my $foo = Foo->new();
    $foo->name('Fred')->who(); # My name is Fred!

# DESCRIPTION

This module exists for your method chaining enjoyment.  It
was originally developed in order to support the porting of
[MooseX::Attribute::Chained](https://metacpan.org/pod/MooseX::Attribute::Chained) using classes to [Moo](https://metacpan.org/pod/Moo).

In [Moose](https://metacpan.org/pod/Moose) you would write:

    package Bar;
    use Moose;
    use MooseX::Attribute::Chained;
    has baz => ( is=>'rw', traits=>['Chained'] );

To port the above to [Moo](https://metacpan.org/pod/Moo) just change it to:

    package Bar;
    use Moo;
    use MooX::ChainedAttributes;
    has baz => ( is=>'rw', chained=>1 );

# AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

# CONTRIBUTORS

- Graham Knop <haarg@haarg.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

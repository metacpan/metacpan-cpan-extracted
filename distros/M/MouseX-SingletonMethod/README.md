# NAME

MouseX::SingletonMethod - Mouse with Singleton Method facility

# SYNOPSIS

    package Foo;
    use MouseX::SingletonMethod;
    no MouseX::Singleton;
    
    package main;
    my $foo1 = Foo->new;
    my $foo2 = Foo->new;
    
    $foo1->add_singleton_method( foo => sub { 'foo' } );
    
    say $foo1->foo; # => 'foo'
    say $foo2->foo; # ERROR: Can't locate object method "foo" ...

or

    package Bar;
    use Mouse;
    with 'MouseX::SingletonMethod::Role';

    no Mouse;

# DESCRIPTION

This module can create singleton methods with Mouse.

# METHODS

## become\_singleton

Make the object a singleton

## add\_singleton\_method

Adds a singleton method to this object:

    $foo->add_singleton_method( foo => sub { 'foo' } );

## add\_singleton\_methods

Same as above except allows multiple method declaration:

    $bar->add_singleton_methods(
        bar1 => sub { 'bar1' },
        bar2 => sub { 'bar2' },
    );

# SEE ALSO

[Mouse](https://metacpan.org/pod/Mouse)
[MooseX::SingletonMethod](https://metacpan.org/pod/MooseX::SingletonMethod)

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

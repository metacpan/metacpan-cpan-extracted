# NAME

MooseX::AttributeFilter - MooX::AttributeFilter with cute antlers OwO

# SYNOPSIS

    package My::Class;
    use Moose;
    use MooseX::AttributeFilter;
    
    has field => (
        is     => 'rw',
        filter => 'filterField',
    );
    
    sub filterField {
        my $this = shift;
        return "filtered($_[0])";
    }
    
    package main;
    my $obj = My::Class->new( field => "initial" );
    $obj->field eq "filtered(initial)"; # True!

# DESCRIPTION

MooseX::AttributeFilter is a port of [MooX::AttributeFilter](https://metacpan.org/pod/MooX::AttributeFilter) to [Moose](https://metacpan.org/pod/Moose).

Filter is like a `coerce` sub but is called as a method so can see object instance.

Filter is like a `trigger` but is called before attribute value is set.

# BUGS

Some parts don't work correctly in mutable classes. Mutable classes are slow anyway.

[https://rt.cpan.org/Dist/Display.html?Queue=MooseX-AttributeFilter](https://rt.cpan.org/Dist/Display.html?Queue=MooseX-AttributeFilter)

# CUTE

<div>
    <img height="680" width="500" src="https://data.whicdn.com/images/129435330/large.jpg" alt="cute kitty girl" />
</div>

Cute.

# SEE ALSO

[MooX::AttributeFilter](https://metacpan.org/pod/MooX::AttributeFilter), [Moose](https://metacpan.org/pod/Moose).

[MooseX::AttributeFilter::Trait::Attribute](https://metacpan.org/pod/MooseX::AttributeFilter::Trait::Attribute),
[MooseX::AttributeFilter::Trait::Attribute::Role](https://metacpan.org/pod/MooseX::AttributeFilter::Trait::Attribute::Role).

# LICENSE

Copyright (C) 2018 Little Princess Kitten <kitten@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

KITTEN <kitten@cpan.org>

[https://metacpan.org/author/KITTEN](https://metacpan.org/author/KITTEN)

[https://github.com/icklekitten](https://github.com/icklekitten)

<3

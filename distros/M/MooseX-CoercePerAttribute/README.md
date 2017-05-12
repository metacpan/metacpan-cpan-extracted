# NAME

MooseX::CoercePerAttribute - Define Coercions per attribute!

# SYNOPSIS

    use MooseX::CoercePerAttribute;

    has foo => (isa => 'Str', is => 'ro', coerce => 1);
    has bar => (
        traits  => [CoercePerAttribute],
        isa     => Bar,
        is      => 'ro',
        coerce  => [
            Str => sub {
                my ($value, $options);
                ...
            },
            Int => sub {
                my ($value, $options);
                ...
            },
        ],
    );

    use Moose::Util::Types;

    has baz => (
        traits  => [CoercePerAttribute],
        isa     => Baz,
        is      => 'ro',
        coerce  => [
            sub {
                coerce $_[0], from Str, via {}
                }]
        );

# DESCRIPTION

MooseX::CoercePerAttribute is a simple Moose Trait to allow you to define inline coercions per attribute.

This module allows for coercions to be declared on a per attribute bases. Accepting either an array of  Code refs of the coercion to be run or an HashRef of various arguments to create a coercion routine from.

# USAGE

This trait allows you to declare a type coercion inline for an attribute. The Role will create an \_\_ANON\_\_ sub TypeConstraint object of the TypeConstraint in the attributes isa parameter. The type coercion can be supplied in one of two methods. The coercion should be supplied to the Moose Attribute coerce parameter.

1\. The recomended usage is to supply a arrayref list declaring the types to coerce from and a subref to be executed in pairs.
    coerce => \[$Fromtype1 => sub {}, $Fromtype2 => sub {}\]

2\. Alternatively you can supply and arrayref of coercion coderefs. These should be in the same format as defined in [Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose::Util::TypeConstraints) and will be passed the \_\_ANON\_\_ subtype as its first argument. If you use this method then you will need to use Moose::Util::TypeConstraints in you module.
    coerce => \[sub {coerce $\_\[0\], from Str, via sub {} }\]

NB: Moose handles its coercions as an array of possible coercions. This means that it will use the first coercion in the list that matches the criteria. In earlier versions of this module the coercions were supplied as a HASHREF. This behaviour is deprecated and will be removed in later versions as it creates an uncertainty over the order of usage.

# AUTHOR

Mike Francis <ungrim97@gmail.com>

# COPYRIGHT

Copyright 2013- Mike Francis

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::CoercePerAttribute

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-CoercePerAttribute](http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-CoercePerAttribute)

- Meta CPAN

    [https://metacpan.org/module/MooseX::CoercePerAttribute](https://metacpan.org/module/MooseX::CoercePerAttribute)

- Search CPAN

    [http://search.cpan.org/dist/MooseX-CoercePerAttribute/](http://search.cpan.org/dist/MooseX-CoercePerAttribute/)

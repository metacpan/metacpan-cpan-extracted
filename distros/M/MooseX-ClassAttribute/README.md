# NAME

MooseX::ClassAttribute - Declare class attributes Moose-style

# VERSION

version 0.29

# SYNOPSIS

    package My::Class;

    use Moose;
    use MooseX::ClassAttribute;

    class_has 'Cache' =>
        ( is      => 'rw',
          isa     => 'HashRef',
          default => sub { {} },
        );

    __PACKAGE__->meta()->make_immutable();

    no Moose;
    no MooseX::ClassAttribute;

    # then later ...

    My::Class->Cache()->{thing} = ...;

# DESCRIPTION

This module allows you to declare class attributes in exactly the same
way as object attributes, using `class_has()` instead of `has()`.

You can use any feature of Moose's attribute declarations, including
overriding a parent's attributes, delegation (`handles`), attribute traits,
etc. All features should just work. The one exception is the "required" flag,
which is not allowed for class attributes.

The accessor methods for class attribute may be called on the class
directly, or on objects of that class. Passing a class attribute to
the constructor will not set that attribute.

# FUNCTIONS

This class exports one function when you use it, `class_has()`. This
works exactly like Moose's `has()`, but it declares class attributes.

One little nit is that if you include `no Moose` in your class, you won't
remove the `class_has()` function. To do that you must include `no
MooseX::ClassAttribute` as well. Or you can just use [namespace::autoclean](https://metacpan.org/pod/namespace::autoclean)
instead.

## Implementation and Immutability

This module will add a role to your class's metaclass, See
[MooseX::ClassAttribute::Trait::Class](https://metacpan.org/pod/MooseX::ClassAttribute::Trait::Class) for details. This role
provides introspection methods for class attributes.

Class attributes themselves do the
[MooseX::ClassAttribute::Trait::Attribute](https://metacpan.org/pod/MooseX::ClassAttribute::Trait::Attribute) role.

## Cooperation with Metaclasses and Traits

This module should work with most attribute metaclasses and traits,
but it's possible that conflicts could occur. This module has been
tested to work with Moose's native traits.

## Class Attributes in Roles

You can add a class attribute to a role. When that role is applied to a class,
the class will have the relevant class attributes added. Note that attribute
defaults will be calculated when the class attribute is composed into the
class.

# SUPPORT

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-ClassAttribute)
(or [bug-moosex-classattribute@rt.cpan.org](mailto:bug-moosex-classattribute@rt.cpan.org)).

I am also usually active on IRC as 'drolsky' on `irc://irc.perl.org`.

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Andrew Rodland <andrew@cleverdomain.org>
- Karen Etheridge <ether@cpan.org>
- Rafael Kitover <rkitover@cpan.org>
- Robert Buels <rmb32@cornell.edu>
- Shawn M Moore <sartak@gmail.com>

# COPYRIGHT AND LICENCE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

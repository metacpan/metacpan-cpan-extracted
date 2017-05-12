# NAME

MooseX::StrictConstructor - Make your object constructors blow up on unknown attributes

# VERSION

version 0.21

# SYNOPSIS

    package My::Class;

    use Moose;
    use MooseX::StrictConstructor;

    has 'size' => ( is => 'ro' );

    # then later ...

    # this blows up because color is not a known attribute
    My::Class->new( size => 5, color => 'blue' );

# DESCRIPTION

Simply loading this module makes your constructors "strict". If your
constructor is called with an attribute init argument that your class does not
declare, then it calls `Moose->throw_error()`. This is a great way to
catch small typos.

## Subverting Strictness

You may find yourself wanting to have your constructor accept a
parameter which does not correspond to an attribute.

In that case, you'll probably also be writing a `BUILD()` or
`BUILDARGS()` method to deal with that parameter. In a `BUILDARGS()`
method, you can simply make sure that this parameter is not included
in the hash reference you return. Otherwise, in a `BUILD()` method,
you can delete it from the hash reference of parameters.

    sub BUILD {
        my $self   = shift;
        my $params = shift;

        if ( delete $params->{do_something} ) {
            ...
        }
    }

# BUGS

Please report any bugs or feature requests to
`bug-moosex-strictconstructor@rt.cpan.org`, or through the web
interface at [http://rt.cpan.org](http://rt.cpan.org).  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

Bugs may be submitted at [https://github.com/moose/MooseX-StrictConstructor/issues](https://github.com/moose/MooseX-StrictConstructor/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for MooseX-StrictConstructor can be found at [https://github.com/moose/MooseX-StrictConstructor](https://github.com/moose/MooseX-StrictConstructor).

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

- Jesse Luehrs <doy@tozt.net>
- Karen Etheridge <ether@cpan.org>
- Ricardo Signes <rjbs@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 - 2017 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.

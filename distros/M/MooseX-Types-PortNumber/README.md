# NAME

MooseX::Types::PortNumber - Port number type for moose classes by The Internet Assigned Numbers Authority (IANA)

# VERSION

version 0.03

# SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Types::PortNumber
        qw( PortNumber PortWellKnow PortRegistered PortPrivate );

    has port => ( isa => PortNumber,     is => 'ro' );
    has well => ( isa => PortWellKnow,   is => 'ro' );
    has reg  => ( isa => PortRegistered, is => 'ro' );
    has priv => ( isa => PortPrivate,    is => 'ro' );

# DESCRIPTION

The port numbers are divided into three ranges: the Well Known Ports, the
Registered Ports, and the Dynamic and/or Private Ports.

The Well Known Ports are those from 0 through 1023.

DCCP Well Known ports SHOULD NOT be used without IANA registration.  The
registration procedure is defined in \[RFC4340\], Section 19.9.

The Registered Ports are those from 1024 through 49151

DCCP Registered ports SHOULD NOT be used without IANA registration.  The
registration procedure is defined in \[RFC4340\], Section 19.9.

The Dynamic and/or Private Ports are those from 49152 through 65535

# SEE ALSO

http://www.iana.org/assignments/port-numbers

# SUPPORT

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-PortNumber)
(or [bug-moosex-types-portnumber@rt.cpan.org](mailto:bug-moosex-types-portnumber@rt.cpan.org)).

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

# AUTHORS

- Thiago Rondon <thiago@aware.com.br>
- Dave Rolsky <autarch@urth.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thiago Rondon & Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

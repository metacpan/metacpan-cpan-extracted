package MooseX::Types::PortNumber;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.03';

use MooseX::Types -declare =>
    [qw(PortNumber PortWellKnow PortRegistered PortPrivate)];
use MooseX::Types::Moose qw(Int);

subtype PortNumber,
    as Int,
    where { $_ >= 0 && $_ <= 65535 },
    inline_as {
    $_[0]->parent()->_inline_check( $_[1] )
        . " && ( $_[1] >= 0 && $_[1] <= 65535 ) "
    },
    message {'Ports are those from 0 through 65535'};

subtype PortWellKnow,
    as Int,
    where { $_ >= 0 && $_ <= 1023 },
    inline_as {
    $_[0]->parent()->_inline_check( $_[1] )
        . " && ( $_[1] >= 0 && $_[1] <= 1023 ) "
    },
    message {'The Well Known Ports are those from 0 through 1023.'};

subtype PortRegistered,
    as Int,
    where { $_ >= 1024 && $_ <= 49151 },
    inline_as {
    $_[0]->parent()->_inline_check( $_[1] )
        . " && ( $_[1] >= 1024 && $_[1] <= 49151 ) "
    },
    message {'The Registered Ports are those from 1024 through 49151'};

subtype PortPrivate,
    as Int,
    where { $_ >= 49152 && $_ <= 65535 },
    inline_as {
    $_[0]->parent()->_inline_check( $_[1] )
        . " && ( $_[1] >= 49152 && $_[1] <= 65535 ) "
    },
    message {
    'The Dynamic and/or Private Ports are those from 49152 through 65535'
    };

1;

# ABSTRACT: Port number type for moose classes by The Internet Assigned Numbers Authority (IANA)

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::PortNumber - Port number type for moose classes by The Internet Assigned Numbers Authority (IANA)

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Types::PortNumber
        qw( PortNumber PortWellKnow PortRegistered PortPrivate );

    has port => ( isa => PortNumber,     is => 'ro' );
    has well => ( isa => PortWellKnow,   is => 'ro' );
    has reg  => ( isa => PortRegistered, is => 'ro' );
    has priv => ( isa => PortPrivate,    is => 'ro' );

=head1 DESCRIPTION

The port numbers are divided into three ranges: the Well Known Ports, the
Registered Ports, and the Dynamic and/or Private Ports.

The Well Known Ports are those from 0 through 1023.

DCCP Well Known ports SHOULD NOT be used without IANA registration.  The
registration procedure is defined in [RFC4340], Section 19.9.

The Registered Ports are those from 1024 through 49151

DCCP Registered ports SHOULD NOT be used without IANA registration.  The
registration procedure is defined in [RFC4340], Section 19.9.

The Dynamic and/or Private Ports are those from 49152 through 65535

=head1 SEE ALSO

http://www.iana.org/assignments/port-numbers

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Types-PortNumber>
(or L<bug-moosex-types-portnumber@rt.cpan.org|mailto:bug-moosex-types-portnumber@rt.cpan.org>).

I am also usually active on IRC as 'drolsky' on C<irc://irc.perl.org>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHORS

=over 4

=item *

Thiago Rondon <thiago@aware.com.br>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thiago Rondon & Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

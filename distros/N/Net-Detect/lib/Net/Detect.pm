package Net::Detect;

use strict;
use warnings;

$Net::Detect::VERSION = '0.3';

use Net::Ping 2.41 ();

sub import {
    no strict 'refs';    ## no critic
    *{ caller() . '::detect_net' } = \&detect_net;
}

sub detect_net {
    my ( $host, $port, @new ) = @_;

    $host ||= 'www.google.com';
    $port ||= 80;
    $port = 80 if !abs( int($port) );

    my $np = Net::Ping->new( @new ? @new : 'syn' );
    $np->port_number($port);
    my $has_net = $np->ping($host);
    $np->close();

    return 1 if $has_net;
    return;
}

1;

__END__

=head1 NAME

Net::Detect - Detect network/internet connectivity

=head1 VERSION

This document describes Net::Detect version 0.3

=head1 SYNOPSIS

    use Test::More;
    use Net::Detect;

    if (detect_net()) {
        plan tests => 42;
    }
    else {
        plan skip_all => 'These tests require an internet connection.';
    }

Or for a specific host/port:

    use Test::More;
    use Net::Detect;

    if (detect_net('xyz.example.com', 8699)) {
        plan tests => 42;
    }
    else {
        plan skip_all => 'These tests require connectivity to xyz.example.com over port 8699.';
    }

=head1 DESCRIPTION

Detect network connectivity with a given host/port.

=head1 INTERFACE 

import() exports detect_net().

=head2 detect_net()

Takes these otpional arguments:

=over 4

=item First: Host (default www.google.com)

    detect_net('example.com')

=item Second: Port (default 80)

    detect_net('example.com', 8699)

=item Rest: passed to L<Net::Ping>->new() (default 'syn')

    detect_net('example.com', 8699, 'tcp', 2)

=back

Returns true when it could pinged. False otherwise.

=head1 DIAGNOSTICS

Any warnings/errors would be from L<Net::Ping>.

=head1 CONFIGURATION AND ENVIRONMENT

Net::Detect requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Net::Ping>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-detect@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

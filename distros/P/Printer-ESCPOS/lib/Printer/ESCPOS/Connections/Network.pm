use strict;
use warnings;

package Printer::ESCPOS::Connections::Network;

# PODNAME: Printer::ESCPOS::Connections::Network
# ABSTRACT: Network Connection Interface for L<Printer::ESCPOS>
#
# This file is part of Printer-ESCPOS
#
# This software is copyright (c) 2017 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.006'; # VERSION

# Dependencies

use 5.010;
use Moo;
with 'Printer::ESCPOS::Roles::Connection';

use IO::Socket;


has deviceIP => ( is => 'ro', );


has devicePort => (
    is      => 'ro',
    default => '9100',
);

has _connection => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build__connection {
    my ($self) = @_;
    my $printer;

    $printer = IO::Socket::INET->new(
        Proto    => "tcp",
        PeerAddr => $self->deviceIP,
        PeerPort => $self->devicePort,
        Timeout  => 1,
    ) or die " Can't connect to printer";

    return $printer;
}


sub read {
    my ( $self, $question, $bytes ) = @_;
    my $data;
    $bytes ||= 2;

    say unpack( "H*", $question );
    $self->_connection->write($question);
    $self->_connection->read( $data, $bytes );

    return $data;
}

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Connections::Network - Network Connection Interface for L<Printer::ESCPOS>

=head1 VERSION

version 1.006

=head1 ATTRIBUTES

=head2 deviceIP

Contains the IP address of the device when its a network printer. The module creates IO:Socket::INET object to connect
to the printer. This can be passed in the constructor.

=head2 devicePort

Contains the network port of the device when its a network printer. The module creates IO:Socket::INET object to connect
to the printer. This can be passed in the constructor.

=head1 METHODS

=head2 read

Read Data from the printer

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

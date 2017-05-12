package Port::Selector;
use strict;
use warnings;

our $VERSION = '0.1.6';

use IO::Socket::INET;
use Class::Tiny {
    min   => 49152,
    max   => 65535,
    proto => 'tcp',
    addr  => 'localhost',
};

=head1 NAME

Port::Selector - pick some unused port

=head1 SYNOPSIS

    my $port_sel = Port::Selector->new();
    $port_sel->port();

=head1 DESCRIPTION

This module is used to find a free port,
by default in the range 49152 to 65535,
but you can change the range of ports that will be checked.

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 min

lowest numbered port to consider

default I<49152>

The range 49152-65535 is commonly used by applications that utilize a
dynamic/random/configurable port.

=head4 max

highest numbered port to consider

default I<65535>

=head4 proto

socket protocol

default I<tcp>

=head4 addr

local address

default I<localhost>

=head2 port()

Tries to find an unused port from C<min>-C<max> ports range,
checking each port in turn until it finds an available one.

=cut

sub port {
    my ($self) = @_;

    foreach my $port ($self->min .. $self->max) {
        my $sock = IO::Socket::INET->new(
            LocalAddr => $self->addr,
            LocalPort => $port,
            Proto     => $self->proto,
            ReuseAddr => $^O ne 'MSWin32',
        );

        if ($sock) {
            close $sock;

            return $port;
        }
    }

    return;
}

=head1 SEE ALSO

L<Net::EmptyPort> (part of the C<Test-TCP> distribution,
provides a function C<empty_port>
which does the same thing as the C<port> method in this module.

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;

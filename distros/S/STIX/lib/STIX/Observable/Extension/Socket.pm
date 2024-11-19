package STIX::Observable::Extension::Socket;

use 5.010001;
use strict;
use warnings;
use utf8;

use STIX::Common::Enum;
use Types::Standard qw(Str Int Enum Bool HashRef);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    address_family
    is_blocking
    is_listening
    options
    socket_type
    socket_descriptor
    socket_handle
]);

use constant EXTENSION_TYPE => 'socket-ext';

has address_family    => (is => 'rw', required => 1, isa => Enum [STIX::Common::Enum->NETWORK_SOCKET_ADDRESS_FAMILY()]);
has is_blocking       => (is => 'rw', isa      => Bool);
has is_listening      => (is => 'rw', isa      => Bool);
has options           => (is => 'rw', isa      => HashRef);
has socket_type       => (is => 'rw', isa      => Enum [STIX::Common::Enum->NETWORK_SOCKET_TYPE()]);
has socket_descriptor => (is => 'rw', isa      => Int);
has socket_handle     => (is => 'rw', isa      => Int);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::Socket - STIX Cyber-observable Object (SCO) - Socket Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::Socket;

    my $socket_ext = STIX::Observable::Extension::Socket->new();


=head1 DESCRIPTION

The Network Socket extension specifies a default extension for capturing network
traffic properties associated with network sockets.


=head2 METHODS

L<STIX::Observable::Extension::Socket> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::Socket->new(%properties)

Create a new instance of L<STIX::Observable::Extension::Socket>.

=item $socket_ext->address_family

Specifies the address family (AF_*) that the socket is configured for
(see C<NETWORK_SOCKET_ADDRESS_FAMILY> in L<STIX::Common::Enum>).

=item $socket_ext->is_blocking

Specifies whether the socket is in blocking mode.

=item $socket_ext->is_listening

Specifies whether the socket is in listening mode.

=item $socket_ext->options

Specifies any options (SO_*) that may be used by the socket, as a dictionary.

=item $socket_ext->socket_type

Specifies the type of the socket (see C<NETWORK_SOCKET_TYPE> in L<STIX::Common::Enum>).

=item $socket_ext->socket_descriptor

Specifies the socket file descriptor value associated with the socket, as a
non-negative integer.

=item $socket_ext->socket_handle

Specifies the handle or inode value associated with the socket.

=back


=head2 HELPERS

=over

=item $socket_ext->TO_JSON

Helper for JSON encoders.

=item $socket_ext->to_hash

Return the object HASH.

=item $socket_ext->to_string

Encode the object in JSON.

=item $socket_ext->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

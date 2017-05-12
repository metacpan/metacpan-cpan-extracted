package Net::NSCA::Client::Connection;

use 5.008001;
use strict;
use warnings 'all';

###############################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.009002';

###############################################################################
# MOOSE
use Moose 0.89;
use MooseX::StrictConstructor 0.08;

###############################################################################
# MOOSE TYPES
use Net::NSCA::Client::Library qw(Hostname PortNumber Timeout);

###############################################################################
# MODULES
use Const::Fast qw(const);
use English qw(-no_match_vars);
use IO::Socket::INET;
use Net::NSCA::Client::InitialPacket;
use Net::NSCA::Client::ServerConfig ();

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# CONSTANTS
const our $DEFAULT_TIMEOUT  => 10;
const our $SOCKET_READ_SIZE => 512;

###############################################################################
# ATTRIBUTES
has initial_packet => (
	is => 'ro',

	builder  => '_build_initial_packet',
	clearer  => '_clear_initial_packet',
	init_arg => undef,
	lazy     => 1,
);
has remote_host => (
	is  => 'ro',
	isa => Hostname,

	required => 1,
);
has remote_port => (
	is  => 'ro',
	isa => PortNumber,

	required => 1,
);
has server_config => (
	is  => 'ro',
	isa => 'Net::NSCA::Client::ServerConfig',

	default => sub { Net::NSCA::Client::ServerConfig->new },
);
has timeout => (
	is  => 'rw',
	isa => Timeout,

	default => $DEFAULT_TIMEOUT,
);
has transport_layer_security => (
	is  => 'rw',
	isa => 'Net::NSCA::Client::Connection::TLS',

	clearer   => 'clear_transport_layer_security',
	predicate => 'has_transport_layer_security',
);
has 'socket' => (
	is => 'ro',

	builder   => '_build_socket',
	clearer   => '_clear_socket',
	init_arg  => undef,
	lazy      => 1,
);

###############################################################################
# METHODS
sub restart {
	my ($self) = @_;

	# Reset the connection by clearing the socket and initial packet
	$self->_clear_initial_packet;
	$self->_clear_socket;

	return $self;
}
sub send_data_packet {
	my ($self, $data_packet) = @_;

	if ($self->server_config != $data_packet->server_config) {
		# The server's configuration for the packet does not match the connection
		Moose->throw_error(sprintf 'Unable to send data packet over connection: %s',
			'Data packet server configuration does not match connection server configration');
	}

	if ($data_packet->unix_timestamp != $self->initial_packet->unix_timestamp) {
		# The timestamp of the pack is incorrect. Repackage the data packet
		# to the correct timestamp.
		$data_packet = $data_packet->clone(
			unix_timestamp => $self->initial_packet->unix_timestamp,
		);
	}

	# Get the byte representation of the packet
	my $byte_packet = $data_packet->raw_packet;

	if ($self->has_transport_layer_security) {
		# Encrypt the data packet
		$byte_packet = $self->transport_layer_security->encrypt(
			byte_stream => $byte_packet,
			iv          => $self->initial_packet->initialization_vector,
		);
	}

	# Send the data packet over the socket
	if (!defined $self->socket->syswrite($byte_packet)) {
		# An error occurred during transmission
		Moose->throw_error(sprintf 'An error occurred during data packet transmission: %s',
			$ERRNO);
	}

	# Reset the connection after a successful write
	$self->restart;

	# Return self
	return $self;
}

###############################################################################
# PRIVATE METHODS
sub _build_initial_packet {
	my ($self) = @_;

	# Create a scalar to store recieved bytes in
	my $received_bytes;

	# Read the bytes
	## no critic (Subroutines::ProtectPrivateSubs)
	my $recv = $self->socket->sysread($received_bytes,
		$self->server_config->_c_packer->sizeof('init_packet_struct'));

	if ($recv == 0) {
		# Reached EOF
		Moose->throw_error('Remote host terminated connection');
	}

	# Create the initial packet object
	my $initial_packet = Net::NSCA::Client::InitialPacket->new(
		raw_packet    => $received_bytes,
		server_config => $self->server_config,
	);

	# Return the initial packet
	return $initial_packet;
}
sub _build_socket {
	my ($self) = @_;

	# Create the socket
	my $socket = IO::Socket::INET->new(
		Blocking => 1,
		PeerAddr => $self->remote_host,
		PeerPort => $self->remote_port,
		Proto    => 'tcp',
		Timeout  => $self->timeout,
	);

	if (!defined $socket) {
		# The socket failed to be created
		Moose->throw_error(sprintf 'Creating a new socket resulted in %s',
			$ERRNO);
	}

	# Return the socket
	return $socket;
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::NSCA::Client::Connection - Represents a connection between the client and
the server.

=head1 VERSION

This documentation refers to version 0.009002

=head1 SYNOPSIS

  use Net::NSCA::Client::Connection;

  # Create a new connection
  my $connection = Net::NSCA::Client::Connection->new(
      remote_host => 'nagios.example.net',
      remote_port => $nsca_port,
  );

  # Send a packet
  $connection->send_data_packet($data_packet);

=head1 DESCRIPTION

Represents a connection between the NSCA client and server.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new object.

=over

=item new(%attributes)

C<%attributes> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item new($attributes)

C<$attributes> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 initial_packet

This is a L<Net::NSCA::Client::InitialPacket|Net::NSCA::Client::InitialPacket>
object which represents the initial packet received when the connection to
the NSCA server was established.

=head2 remote_host

B<Required>

This is the host name or IP address of the remote NSCA server.

=head2 remote_port

B<Required>

This is the port number of the remote NSCA server.

=head2 server_config

This specifies the configuration of the remote NSCA server. See
L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig> for details
about using this. Typically this does not need to be specified unless the
NSCA server was compiled with customizations.

=head2 timeout

This is the timeout for reading from the socket. The default is set to
L</$DEFAULT_TIMEOUT>.

=head2 transport_layer_security

This is a L<Net::NSCA::Client::Connection::TLS|Net::NSCA::Client::Connection::TLS>
object that specifies the transport layer security that will be used when
sending the data packet.

=head2 socket

This is the socket object (L<IO::Socket::INET|O::Socket::INET>) that
represents the TCP connection to the NSCA server.

=head1 METHODS

=head2 restart

This will restart the connection.

=head2 clear_transport_layer_security

This will clear the L</transport_layer_security> attribute removing any
transport layer security.

=head2 has_transport_layer_security

This will return a Boolean of if the connection is protected by transport
layer security.

=head2 send_data_packet

This will send a data packet to the remote NSCA server. The method takes one
argument which is the L<Net::NSCA::Client::DataPacket|Net::NSCA::Client::DataPacket>
object. If the UNIX timestamp of the data packet is not set to the correct
timestamp the server is expecting, then the data packet is cloned and the
correct timestamp is set before sending the packet.

=head1 CONSTANTS

Constants provided by this library are protected by the
L<Const::Fast|Const::Fast> module.

=head2 C<$DEFAULT_TIMEOUT>

This is the default timeout that will be used if no timeout value is specified.

=head2 C<$SOCKET_READ_SIZE>

This is the number of bytes that will be read from the socket at a time.

=head1 DEPENDENCIES

=over

=item * L<Const::Fast|Const::Fast>

=item * L<English|English>

=item * L<IO::Socket::INET|IO::Socket::INET>

=item * L<Net::NSCA::Client::InitialPacket|Net::NSCA::Client::InitialPacket>

=item * L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig>

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-net-nsca-client at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-NSCA-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

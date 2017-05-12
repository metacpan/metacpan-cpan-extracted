package Net::NSCA::Client;

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
use Net::NSCA::Client::Library 0.009 qw(Bytes Hostname PortNumber Timeout);

###############################################################################
# MODULES
use Const::Fast qw(const);
use Net::NSCA::Client::Connection;
use Net::NSCA::Client::Connection::TLS;
use Net::NSCA::Client::DataPacket;
use Net::NSCA::Client::ServerConfig ();

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# CONSTANTS
const our $DEFAULT_HOST    => '127.0.0.1';
const our $DEFAULT_PORT    => 5667;
const our $DEFAULT_TIMEOUT => 10;
const our $STATUS_OK       => 0;
const our $STATUS_WARNING  => 1;
const our $STATUS_CRITICAL => 2;
const our $STATUS_UNKNOWN  => 3;

###############################################################################
# ATTRIBUTES
has encryption_password => (
	is  => 'rw',
	isa => Bytes,

	clearer   => 'clear_encryption_password',
	coerce    => 1,
	predicate => 'has_encryption_password',
);
has encryption_type => (
	is  => 'rw',
	isa => 'Str',

	default => 'none',
);
has remote_host => (
	is  => 'rw',
	isa => Hostname,

	default => $DEFAULT_HOST,
);
has remote_port => (
	is  => 'rw',
	isa => PortNumber,

	default => $DEFAULT_PORT,
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

###############################################################################
# METHODS
sub send_report {
	my ($self, %args) = @_;

	# Splice out the arguments
	my ($hostname, $service, $message, $status) = @args{qw(
	     hostname   service   message   status)};

	# Copy some attributes for this for the connection
	my @connection_args = map { $_ => $self->$_ }
		(qw[remote_host remote_port server_config timeout]);

	if ($self->encryption_type ne 'none') {
		# Start the TLS object arguments
		my @tls_args = (
			encryption_type => $self->encryption_type,
		);

		if ($self->has_encryption_password) {
			# Add the password
			push @tls_args, password => $self->encryption_password;
		}

		# Create a TLS object for the connection
		my $tls = Net::NSCA::Client::Connection::TLS->new(@tls_args);

		# Add the TLS object to the connection
		push @connection_args, transport_layer_security => $tls;
	}

	# Create a new connection to the remote server
	my $connection = Net::NSCA::Client::Connection->new(@connection_args);

	# Create a data packet to send back
	my $data_packet = Net::NSCA::Client::DataPacket->new(
		hostname            => $hostname,
		service_description => $service,
		service_message     => $message,
		service_status      => $status,
		server_config       => $self->server_config,
	);

	# Send back the data packet
	$connection->send_data_packet($data_packet);

	# Nothing good to return, so return self
	return $self;
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::NSCA::Client - Send passive checks to Nagios locally and remotely.

=head1 VERSION

This documentation refers to version 0.009002

=head1 SYNOPSIS

  use Net::NSCA::Client;

  my $nsca = Net::NSCA::Client->new(
    remote_host => 'nagios.example.net',
  );

  $nsca->send_report(
    hostname => 'web1.example.net',
    service  => 'MYSQL',
    message  => $plugin_output,
    status   => $Net::NSCA::Client::STATUS_OK,
  );

=head1 DESCRIPTION

Send passive checks to Nagios locally and remotely.

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

=head2 encryption_password

This is the password to use with the encryption.

=head2 encryption_type

This is a string of the encryption type. See
L<Net::NSCA::Client::Connection::TLS|Net::NSCA::Client::Connection::TLS>
for the different encryption types.

=head2 remote_host

This is the remote host to connect to. This will default to L</$DEFAULT_HOST>.

=head2 remote_port

This is the remote port to connect to. This will default to L</$DEFAULT_PORT>.

=head2 server_config

This specifies the configuration of the remote NSCA server. See
L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig> for details
about using this. Typically this does not need to be specified unless the
NSCA server was compiled with customizations.

=head2 timeout

This is the timeout to use when connecting to the service. This will default to
L</$DEFAULT_TIMEOUT>.

=head1 METHODS

=head2 clear_encryption_password

This will remove the encryption password that is currently set.

=head2 hsa_encryption_password

This will return a Boolean if there is any encryption password.

=head2 send_report

This will send a report on a service to the remote NSCA server. This method
takes a HASH of arguments with the following keys:

=head3 hostname

This is the hostname of the service that is being reported.

=head3 service

This is the service description of the service that is being reported.

=head3 message

This is the message that the plug in gives to Nagios.

=head3 status

This is the status code to report to Nagios. You will want to use one of the
C<$STATUS_*> constants.

=head1 SPECIFICATION

The NSCA protocol is currently at L<version 3|/NSCA PROTOCOL 3>. Simply
put, the NSCA protocol is very simple from the perspective for the C
language. The NSCA program has a C structure that is populated and then
sent across the network in raw form.

=head2 NSCA PROTOCOL 1

Currently I cannot find any information on this (it is probably ancient; at
least before 2002). This module does not support this protocol version.

=head2 NSCA PROTOCOL 2

This protocol is identical to L</NSCA PROTOCOL 3> except that the
C<packet_version> is the integer C<2> to match the protocol version. The
difference between the two protocols is that with version 3, passive host
checks were introduced and thus the version had to change otherwise the
server would think that the check was for a service with no name.

=head2 NSCA PROTOCOL 3

This protocol version was first introduced in NSCA version 2.2.

Below is the definition of the C structure taken from C<common.h> in NSCA
version 2.7.2.

  struct data_packet_struct {
    int16_t   packet_version;
    u_int32_t crc32_value;
    u_int32_t timestamp;
    int16_t   return_code;
    char      host_name[MAX_HOSTNAME_LENGTH];
    char      svc_description[MAX_DESCRIPTION_LENGTH];
    char      plugin_output[MAX_PLUGINOUTPUT_LENGTH];
  };

When the client connects to the server, the server sends a packet with the
following C structure taken from C<common.h> in NSCA version 2.7.2.

  struct init_packet_struct {
    char      iv[TRANSMITTED_IV_SIZE];
    u_int32_t timestamp;
  };

The packet is first completely zeroed, and thus made empty. Next, the packet
is filled randomly with alpha-numeric characters. The C library actually fills
it randomly with ASCII characters between C<0x30> and C<0x7A>. All values are
now filled into the structure (only overwriting what needs to be written,
keeping randomness intact). The C<timestamp> value is set to the same value
that was sent by the server in the initial response and C<crc32_value> is set
to all zeros. The CRC32 is calculated for this packet and stored in the packet.
Next, the packet in encrypted with the specified method (which MUST be exactly
as set in the server) and sent across the network.

=head3 Encryption

=head4 None

When there is no encryption, then the packet is completely unchanged.

=head4 XOR

This is the obfucated method and so is no encryption. This is merely to attempt
to mask the data to make it harder to see. The packet is first XOR'd with the
IV that was sent by the server, one byte at a time. Once all bytes from the IV
have been used, then it starts again from the first byte of the IV. After this,
the packet is then XOR'd with the provided password and the same steps as
followed by the IV are followed for the password (byte-per-byte, looping).

=head4 All other Encryptions

All other specified encryption methods are performed in cipher feedback
(CFB) mode, in one bye blocks (even if the encryption method doesn't
actually support being used in one byte block modes.

=head1 CONSTANTS

=head2 C<$DEFAULT_HOST>

The is the default host to use when connecting.

=head2 C<$DEFAULT_PORT>

This is the default port number to use when connecting to a remote host.

=head2 C<$DEFAULT_TIMEOUT>

This is the default timeout to use when connecting to a remote host.

=head2 C<$STATUS_OK>

This is the status value when a service is OK

=head2 C<$STATUS_WARNING>

This is the status value when a service is WARNING

=head2 C<$STATUS_CRITICAL>

This is the status value when a service is CRITICAL

=head2 C<$STATUS_UNKNOWN>

This is the status value when a service is UNKNOWN

=head1 DEPENDENCIES

=over

=item * L<Const::Fast|Const::Fast>

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<Net::NSCA::Client::Connection|Net::NSCA::Client::Connection>

=item * L<Net::NSCA::Client::DataPacket|Net::NSCA::Client::DataPacket>

=item * L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig>

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 SEE ALSO

=over

=item * L<Nagios::NSCA::Client|Nagios::NSCA::Client> is a semi-new NSCA
client that works, but contains no documentation or tests.

=item * L<Net::Nsca|Net::Nsca> is one of the original NSCA Perl modules.

=item * L<POE::Component::Client::NSCA|POE::Component::Client::NSCA> is a
NSCA client that is made for L<the POE framework|POE>.

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

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Net::NSCA::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-NSCA-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-NSCA-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-NSCA-Client/>

=back

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

package Net::NSCA::Client::DataPacket;

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
# MOOSE ROLES
with 'MooseX::Clone';

###############################################################################
# MOOSE TYPES
use Net::NSCA::Client::Library 0.009 qw(Bytes);

###############################################################################
# MODULES
use Digest::CRC ();
use Net::NSCA::Client::ServerConfig ();
use Net::NSCA::Client::Utils qw(initialize_moose_attr_early);

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# OVERLOADED FUNCTIONS
__PACKAGE__->meta->add_package_symbol(q{&()}  => sub {                   });
__PACKAGE__->meta->add_package_symbol(q{&(""} => sub { shift->raw_packet });

###############################################################################
# ATTRIBUTES
has hostname => (
	is  => 'ro',
	isa => 'Str',

	required => 1,
);
has packet_version => (
	is  => 'ro',
	isa => 'Int',

	default       => 3,
	documentation => q{The version of the packet being transmitted},
);
has raw_packet => (
	is  => 'ro',
	isa => Bytes,

	lazy    => 1,
	builder => '_build_raw_packet',
	coerce  => 1,
);
has server_config => (
	is  => 'ro',
	isa => 'Net::NSCA::Client::ServerConfig',

	default => sub { Net::NSCA::Client::ServerConfig->new },
	# Immutable so no need to recursively clone
);
has service_description => (
	is  => 'ro',
	isa => 'Str',

	required => 1,
);
has service_message => (
	is  => 'ro',
	isa => 'Str',

	required => 1,
);
has service_status => (
	is  => 'ro',
	isa => 'Int',

	required => 1,
);
has unix_timestamp => (
	is  => 'ro',
	isa => 'Int',

	default => sub { scalar time },
);

###############################################################################
# CONSTRUCTOR
around BUILDARGS => sub {
	my ($original_method, $class, @args) = @_;

	if (@args == 1 && !ref $args[0]) {
		# This should be the packet as a string, so get the new
		# args from this string
		@args = (raw_packet => $args[0]);
	}

	# Call the original method to get args HASHREF
	my $args = $class->$original_method(@args);

	if (defined(my $raw_packet = initialize_moose_attr_early($class, raw_packet => $args))) {
		# The packet was provided to the constructor

		# Get the server_config as well
		my $server_config = initialize_moose_attr_early($class, server_config => $args);

		# Build constructor arguments from the raw packet
		my $new_args = _constructor_options_from_string($raw_packet, $server_config);

		# Merge the arguments together
		$args = { %{$args}, %{$new_args} };
	}

	return $args;
};

###############################################################################
# METHODS
sub to_string {
	return shift->raw_packet;
}

###############################################################################
# PRIVATE METHODS
sub _build_raw_packet {
	my ($self) = @_;

	# Create a HASH of the value to be provided to the pack
	my %pack_options = (
		crc32_value     => 0,
		host_name       => $self->hostname,
		packet_version  => $self->packet_version,
		plugin_output   => $self->service_message,
		timestamp       => $self->unix_timestamp,
		return_code     => $self->service_status,
		svc_description => $self->service_description,
	);

	# To construct the packet, we will use the pack method from the
	# Convert::Binary::C object
	my $packet = $self->server_config->pack_data_packet(\%pack_options);

	# Repack the packet with the CRC32 value
	$self->server_config->repack_data_packet(\$packet, {
		# Calculate the CRC32 value for the packet
		crc32_value => Digest::CRC::crc32($packet),
	});

	# Return the packet
	return $packet;
}

###############################################################################
# PRIVATE FUNCTIONS
sub _constructor_options_from_string {
	my ($packet, $server_config) = @_;

	if (!defined $server_config) {
		# Get the attribute from the class
		my $attr = __PACKAGE__->meta->find_attribute_by_name('server_config');

		# Set to the class default
		$server_config = $attr->is_default_a_coderef ? $attr->default->()
		                                             : $attr->default
		                                             ;
	}

	if (!_is_packet_valid($packet, $server_config)) {
		Moose->throw_error('Provided packet is not valid');
	}

	# Unpack the data packet
	my $unpacket = $server_config->unpack_data_packet($packet);

	# Return the options for the constructor
	return {
		hostname            => $unpacket->{host_name      },
		packet_version      => $unpacket->{packet_version },
		service_description => $unpacket->{svc_description},
		service_message     => $unpacket->{plugin_output  },
		service_status      => $unpacket->{return_code    },
		unix_timestamp      => $unpacket->{timestamp      },
	};
}
sub _is_packet_valid {
	my ($packet, $server_config) = @_;

	# Extract the CRC from the packet
	my $crc32 = $server_config->unpack_data_packet($packet)->{crc32_value};

	# Repack the packet with CRC32 as zero so that the CRC32 can
	# be recalculated
	$server_config->repack_data_packet(\$packet, {
		crc32_value => 0,
	});

	# Packet is valid if the CRC32 values are the same
	return $crc32 == Digest::CRC::crc32($packet);
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::NSCA::Client::DataPacket - Implements data packet for the NSCA protocol

=head1 VERSION

This documentation refers to version 0.009002

=head1 SYNOPSIS

  use Net::NSCA::Client;
  use Net::NSCA::Client::DataPacket;

  # Create a packet from scratch
  my $packet = Net::NSCA::Client::DataPacket->new(
    hostname            => 'www.example.net',
    service_description => 'Apache',
    service_message     => 'OK - Apache running',
    service_status      => $Net::NSCA::Client::STATUS_OK,
    unix_timestamp      => $iv_timestamp,
  );

  # Create a packet recieved from over the network
  my $recieved_packet = Net::NSCA::Client::DataPacket->new(
      raw_packet => $recieved_data,
  );

=head1 DESCRIPTION

Represents the data packet used in the NSCA protocol.

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

=item new($packet_string)

C<$packet_string> is a string of the data packet in the network form.

=back

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 hostname

B<Required>

This is the host name of the host as listed in Nagios that the service
belongs to.

=head2 packet_version

This is the version of the packet to be sent. A few different NSCA servers use
slightly different version numbers, but the rest of the packet is the same.
If not specified, this will default to 3.

=head2 raw_packet

This is the raw packet to send over the network. Providing this packet to
the constructor will automatically populate all other attributes and so
they are B<not> required if this attribute is provided.

=head2 service_description

B<Required>

This is the service description as listed in Nagios of the service that this
report will be listed under.

=head2 service_message

B<Required>

This is the message that will be given to Nagios.

=head2 service_status

B<Required>

This is the status of the service that will be given to Nagios. It is
recommended to use one of the C<$STATUS_> constants provided by
L<Net::NSCA::Client|Net::NSCA::Client>.

=head2 server_config

This specifies the configuration of the remote NSCA server. See
L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig> for details
about using this. Typically this does not need to be specified unless the
NSCA server was compiled with customizations.

=head2 unix_timestamp

This is a UNIX timestamp, which is an integer specifying the number of
non-leap seconds since the UNIX epoch. This will default to the current UNIX
timestamp.

=head1 METHODS

=head2 to_string

This methods returns the string representation of the data packet. This string
representation is what will be sent over the network.

=head1 DEPENDENCIES

=over

=item * L<Digest::CRC|Digest::CRC>

=item * L<Moose|Moose> 0.89

=item * L<MooseX::Clone|MooseX::Clone>

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig>

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

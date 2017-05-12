package Net::NSCA::Client::InitialPacket;

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
use Net::NSCA::Client::Library 0.009 qw(Bytes);

###############################################################################
# MODULES
use Data::Rand::Obscure 0.020;
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
has initialization_vector => (
	is  => 'ro',
	isa => Bytes,

	builder => '_build_initialization_vector',
	coerce  => 1,
	lazy    => 1,
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
);
has unix_timestamp => (
	is  => 'ro',
	isa => 'Int',

	default => sub { scalar time },
);

###############################################################################
# CONSTRUCTOR
sub BUILD {
	my ($self) = @_;

	# Check length of initialization_vector
	if ($self->server_config->initialization_vector_length
	    != length $self->initialization_vector) {
		Moose->throw_error('initialization_vector is not the correct size');
	}

	return;
}
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
sub _build_initialization_vector {
	my ($self) = @_;

	return Data::Rand::Obscure::create_bin(
		length => $self->server_config->initialization_vector_length,
	);
}
sub _build_raw_packet {
	my ($self) = @_;

	# Create a HASH of the value to be provided to the pack
	my %pack_options = (
		iv        => $self->initialization_vector,
		timestamp => $self->unix_timestamp,
	);

	# To construct the packet, we will use the pack method from the
	# Convert::Binary::C object
	my $packet = $self->server_config->pack_initial_packet(\%pack_options);

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

	# Unpack the data packet
	my $unpacket = $server_config->unpack_initial_packet($packet);

	# Return the options for the constructor
	return {
		initialization_vector => $unpacket->{iv       },
		unix_timestamp        => $unpacket->{timestamp},
	};
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::NSCA::Client::InitialPacket - Implements initial packet for the NSCA
protocol

=head1 VERSION

This documentation refers to version 0.009002

=head1 SYNOPSIS

  use Net::NSCA::Client::InitialPacket;

  # Create a packet from scratch
  my $packet = Net::NSCA::Client::InitialPacket->new(
      initialization_vector => $iv,
      unix_timestamp        => time(),
  );

  # Create a packet recieved from over the network
  my $recieved_packet = Net::NSCA::Client::InitialPacket->new($recieved_data);

=head1 DESCRIPTION

Represents the initial packet used in the NSCA protocol.

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

  # Get an attribute
  my $value = $object->attribute_name;

=head2 initialization_vector

This is a binary string, which is the exact length of the constant
L</$INITIALIZATION_VECTOR_LENGTH>. If a string less than this length is
provided, then it is automatically padded with NULLs. If not specified, this
will default to random bytes generated by a L<Crypt::Random|Crypt::Random>.

=head2 server_config

This specifies the configuration of the remote NSCA server. See
L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig> for details
about using this. Typically this does not need to be specified unless the
NSCA server was compiled with customizations.

=head2 unix_timestamp

This is a UNIX timestamp, which is an integer specifying the number of
non-leap seconds since the UNIX epoch. If not specified, this will default
to the current timestamp, provided by C<time()>.

=head1 METHODS

=head2 to_string

This methods returns the string representation of the initial packet. This
string representation is what will be sent over the network.

=head1 DEPENDENCIES

=over

=item * L<Data::Rand::Obscure|Data::Rand::Obscure> 0.020

=item * L<Moose|Moose> 0.89

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

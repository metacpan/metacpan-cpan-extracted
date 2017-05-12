package Net::NSCA::Client::ServerConfig;

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
# MODULES
use Const::Fast qw(const);
use Convert::Binary::C 0.74 ();
use List::MoreUtils ();

###############################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###############################################################################
# OVERLOADED FUNCTIONS
__PACKAGE__->meta->add_package_symbol(q{&()}  => sub { });
__PACKAGE__->meta->add_package_symbol(q{&(==} => sub {  $_[0]->is_compatible_with($_[1]) });
__PACKAGE__->meta->add_package_symbol(q{&(!=} => sub { !$_[0]->is_compatible_with($_[1]) });

###############################################################################
# PRIVATE CONSTANTS
const my $BYTES_FOR_16BITS => 2;
const my $BYTES_FOR_32BITS => 4;

###############################################################################
# ATTRIBUTES
has initialization_vector_length => (
	is  => 'ro',
	isa => 'Int',

	default => 128,
);
has max_description_length => (
	is  => 'ro',
	isa => 'Int',

	default => 128,
);
has max_hostname_length => (
	is  => 'ro',
	isa => 'Int',

	default => 64,
);
has max_service_message_length => (
	is  => 'ro',
	isa => 'Int',

	default => 512,
);

###############################################################################
# PRIVATE ATTRIBUTES
has _c_packer => (
	is  => 'ro',
	isa => 'Convert::Binary::C',
	init_arg => undef,

	lazy    => 1,
	builder => '_build_c_packer',
);

###############################################################################
# METHODS
sub is_compatible_with {
	my ($self, $server_config) = @_;

	# Attribute list to compare
	my @attribute = (qw[
		initialization_vector_length
		max_description_length
		max_hostname_length
		max_service_message_length
	]);

	# Compatible if all attributes are equal
	return List::MoreUtils::all { $self->$_ == $server_config->$_ } @attribute;
}
sub pack_data_packet {
	my ($self, $args) = @_;

	# Return packed structure
	return $self->_c_packer->pack(data_packet_struct => $args);
}
sub pack_initial_packet {
	my ($self, $args) = @_;

	# Return packed structure
	return $self->_c_packer->pack(init_packet_struct => $args);
}
sub repack_data_packet {
	my ($self, $packet, $args) = @_;

	# Repack the structure and possibly return
	return $self->_repack_structure(
		data_packet_struct => $packet => $args
	);
}
sub repack_initial_packet {
	my ($self, $packet, $args) = @_;

	# Repack the structure and possibly return
	return $self->_repack_structure(
		init_packet_struct => $packet => $args
	);
}
sub unpack_data_packet {
	my ($self, $packet) = @_;

	# Return unpacked structure
	return $self->_unpack_structure(
		data_packet_struct => $packet,
	);
}
sub unpack_initial_packet {
	my ($self, $packet) = @_;

	# Return unpacked structure
	return $self->_unpack_structure(
		init_packet_struct => $packet,
	);
}

###############################################################################
# ATTRIBUTE BUILDERS
sub _build_c_packer {
	my ($self) = @_;

	# Get a new packer object
	my $packer = _setup_c_object();

	# Install the two structures into the C object
	$self->_install_initial_packet_struct($packer);
	$self->_install_data_packet_struct($packer);

	return $packer;
}

###############################################################################
# PRIVATE METHODS
sub _install_initial_packet_struct {
	my ($self, $c) = @_;

	# Constants used in the structure
	my $INITIALIZATION_VECTOR_LENGTH = $self->initialization_vector_length;

	# Add the init_packet_struct structure
	## no critic (ValuesAndExpressions::RequireUpperCaseHeredocTerminator)
	## no critic (CodeLayout::ProhibitHardTabs) otherwise editor doesn't know when here-doc terminates
	$c->parse(<<"	ENDC");
		struct init_packet_struct {
			char      iv[$INITIALIZATION_VECTOR_LENGTH];
			u_int32_t timestamp;
		};
	ENDC

	# Tag the IV as a binary string
	$c->tag('init_packet_struct.iv', Format => 'Binary');

	# Method chaining enabled
	return $self;
}
sub _install_data_packet_struct {
	my ($self, $c) = @_;

	# Constants used in the structure
	my $MAX_HOSTNAME_LENGTH            = $self->max_hostname_length;
	my $MAX_SERVICE_DESCRIPTION_LENGTH = $self->max_description_length;
	my $MAX_SERVICE_MESSAGE_LENGTH     = $self->max_service_message_length;

	# Add the data_packet_struct structure
	## no critic (ValuesAndExpressions::RequireUpperCaseHeredocTerminator)
	## no critic (CodeLayout::ProhibitHardTabs) otherwise editor doesn't know when here-doc terminates
	$c->parse(<<"	ENDC");
		struct data_packet_struct {
			int16_t   packet_version;
			u_int32_t crc32_value;
			u_int32_t timestamp;
			int16_t   return_code;
			char      host_name[$MAX_HOSTNAME_LENGTH];
			char      svc_description[$MAX_SERVICE_DESCRIPTION_LENGTH];
			char      plugin_output[$MAX_SERVICE_MESSAGE_LENGTH];
		};
	ENDC

	# Add the string hooks to all the string members
	foreach my $string_member (qw(host_name svc_description plugin_output)) {
		$c->tag("data_packet_struct.$string_member", Hooks => {
			pack   => [\&_string_randpad_pack, $c->arg(qw(DATA SELF TYPE)), 'data_packet_struct'],
			unpack =>  \&_string_unpack,
		});
	}

	return $self;
}
sub _repack_structure {
	my ($self, $structure_name, $packet, $args) = @_;

	if (ref $packet eq 'SCALAR') {
		# The packet is a reference, so it should be changed in place
		$self->_c_packer->pack($structure_name => $args, ${$packet});

		return $packet;
	}

	# Return the packed structure
	return $self->_c_packer->pack($structure_name => $args, $packet);
}
sub _unpack_structure {
	my ($self, $structure_name, $packet) = @_;

	my $unpacked;

	if (ref $packet eq 'SCALAR') {
		# The packet is a reference, so it should be deferenced
		$unpacked = $self->_c_packer->unpack($structure_name => ${$packet});
	}
	else {
		$unpacked = $self->_c_packer->unpack($structure_name => $packet);
	}

	return $unpacked;
}

###############################################################################
# PRIVATE FUNCTIONS
sub _setup_c_object {
	my ($c) = @_;

	# If no object provided, create a new one
	$c ||= Convert::Binary::C->new;

	# Set the memory structure to store in network order
	$c->ByteOrder('BigEndian');

	# The alignment always seems to be 4 bytes, so set the alignment here
	$c->Alignment($BYTES_FOR_32BITS);

	# Create a HASH of sizes to types
	my %int_sizes;

	$int_sizes{$c->sizeof('int'          )} = 'int';
	$int_sizes{$c->sizeof('long int'     )} = 'long int';
	$int_sizes{$c->sizeof('long long int')} = 'long long int';
	$int_sizes{$c->sizeof('short int'    )} = 'short int';

	# Check the needed types are present
	if (!exists $int_sizes{$BYTES_FOR_16BITS}) {
		Moose->throw_error('Your platform does not have any C data type that is 16 bits');
	}
	if (!exists $int_sizes{$BYTES_FOR_32BITS}) {
		Moose->throw_error('Your platform does not have any C data type that is 32 bits');
	}

	# Now that the sizes are known, set up various typedefs
	my @typedefs = (
		sprintf('typedef %s int16_t;'           , $int_sizes{$BYTES_FOR_16BITS}),
		sprintf('typedef unsigned %s u_int16_t;', $int_sizes{$BYTES_FOR_16BITS}),
		sprintf('typedef %s int32_t;'           , $int_sizes{$BYTES_FOR_32BITS}),
		sprintf('typedef unsigned %s u_int32_t;', $int_sizes{$BYTES_FOR_32BITS}),
	);

	# Have the C object parse the typedefs
	$c->parse(join qq{\n}, @typedefs);

	# Return the object
	return $c;
}
sub _string_randpad_pack {
	my ($string, $c, $type, $struct) = @_;

	if (defined $struct) {
		$type = sprintf '%s.%s', $struct, $type;
	}

	# Cut off the NULL and anything after it
	($string) = $string =~ m{\A ([^\0]+)}msx;

	# Add NULL to the end of the string
	$string .= chr 0;

	# Get the max length
	my $max_length = $c->sizeof($type);

	# Check if the string is too long
	if ($max_length < length $string) {
		Moose->throw_error(sprintf 'The string provided to %s is too long. Max length is %s bytes',
			$type, $max_length - 1);
	}

	# Create an array of letters and numbers
	my @letters_and_numbers = ('a'..'z', 'A'..'Z', '0'..'9');

	# Pad the remaining space with random ASCII characters
	while ($max_length > length $string) {
		$string .= $letters_and_numbers[int rand @letters_and_numbers];
	}

	# Return the string
	return [unpack 'c*', $string];
}
sub _string_unpack {
	my ($c_string) = @_;

	# Return the Perl string
	return unpack 'Z*', pack 'c*', map { defined $_ ? $_ : 0 } @{$c_string};
}

###############################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::NSCA::Client::ServerConfig - Specify configuration data for the remote
NSCA server

=head1 VERSION

This documentation refers to version 0.009002

=head1 SYNOPSIS

  use Net::NSCA::Client::ServerConfig;

  # Specify the non-default server configuration
  my $config = Net::NSCA::Client::ServerConfig->new(
      max_hostname_length     => 100,
      max_description_length  => 128,
      max_pluginoutput_length => 3072, # 3 KiB!
  );

  # Create a new connection with the configuration
  my $connection = Net::NSCA::Client::Connection->new(
      remote_host   => 'nagios.example.net',
      server_config => $config,
  );

  # Create a new client with the configuration
  my $nsca = Net::NSCA::Client->new(
      remote_host   => 'nagios.example.net',
      server_config => $config,
  );

  # Data packets will adhere to the server configuration
  $nsca->send_report(
      hostname => 'web1.example.net',
      service  => 'MYSQL',
      message  => $plugin_output,
      status   => $Net::NSCA::Client::STATUS_OK,
  );

=head1 DESCRIPTION

When NSCA is compiled, there are constants that define the size of the packets
that will be generated and accepted. If NSCA was compiled with custom values
for these constants, then this module will allow the client to generate
corresponding packets.

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

  # Get an attribute
  my $value = $object->attribute_name;

=head2 initialization_vector_length

This specifies the byte length of the initialization vector in the initial
packet as specified in the C<TRANSMITTED_IV_SIZE> constant in F<common.h>.

=head2 max_description_length

This specifies the maximum description length in bytes as specified in
the C<MAX_DESCRIPTION_LENGTH> constant in F<common.h>.

=head2 max_hostname_length

This specifies the maximum host name length in bytes as specified in
the C<MAX_HOSTNAME_LENGTH> constant in F<common.h>.

=head2 max_service_message_length

This specifies the maximum service message (plugin output) length in bytes
as specified in the C<MAX_PLUGINOUTPUT_LENGTH> constant in F<common.h>.

=head1 METHODS

=head2 is_compatible_with

This takes another L<Net::NSCA::Client::ServerConfig|Net::NSCA::Client::ServerConfig>
instance and returns a Boolean specifying if the two server configurations
are compatible with each other. This method is also accessible through an
overloaded C<==> and C<!=>.

=head2 pack_data_packet

This takes a HASHREF that specify the members of the C structure and the
values to pack in each member. This will return a string that is the raw
packed byte data.

=head2 pack_initial_packet

This takes a HASHREF that specify the members of the C structure and the
values to pack in each member. This will return a string that is the raw
packed byte data.

=head2 repack_data_packet

This takes the raw packet as the first argument and a HASHREF (as specified
in L</pack_data_packet>) as the second argument. The first argument (the raw
packet) may be a scalar reference and the packet will be modified in place.
The new raw packet or the same scalar reference will be returned, based on
if the first argument was a scalar reference or not.

  # Repack by copying packet around
  my $no_crc32 = $packer->repack_data_packet($raw_packet, {crc32_value => 0});

  # Repack in place
  $packer->repack_data_packet(\$raw_packet, {crc32_value => 0});

=head2 repack_initial_packet

This takes the raw packet as the first argument and a HASHREF (as specified
in L</pack_initial_packet>) as the second argument. The first argument (the
raw packet) may be a scalar reference and the packet will be modified in
place. The new raw packet or the same scalar reference will be returned,
based on if the first argument was a scalar reference or not. See
L</repack_data_packet> for usage examples.

=head2 unpack_data_packet

This takes the raw packet and returns a HASHREF of the C structure names and
values. The raw packet may be given as a string or as a scalar reference.

=head2 unpack_initial_packet

This takes the raw packet and returns a HASHREF of the C structure names and
values. The raw packet may be given as a string or as a scalar reference.

=head1 DEPENDENCIES

=over

=item * L<Const::Fast|Const::Fast>

=item * L<Convert::Binary::C|Convert::Binary::C> 0.74

=item * L<List::MoreUtils|List::MoreUtils>

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

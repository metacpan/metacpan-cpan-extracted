package Net::RNDC::Packet;
{
  $Net::RNDC::Packet::VERSION = '0.003';
}

use strict;
use warnings;

use Net::RNDC::Exception;

use Try::Tiny;

use UNIVERSAL ();

use Carp qw(croak);
use Digest::HMAC_MD5;
use MIME::Base64 qw(decode_base64);

# lib/isccc/include/isccc/cc.h
use constant ISCCC_CCMSGTYPE_STRING     => 0x00;
use constant ISCCC_CCMSGTYPE_BINARYDATA => 0x01;
use constant ISCCC_CCMSGTYPE_TABLE      => 0x02;
use constant ISCCC_CCMSGTYPE_LIST       => 0x03;

# Serial should be created by users
my $serial = int(rand(2**32));

sub new {
	my ($class, %args) = @_;

	my @required_args = qw(
		key
	);

	my @optional_args = qw(
		version
		data
		nonce
	);

	for my $r (@required_args) {
		unless (exists $args{$r}) {
			croak("Missing required argument '$r'");
		}
	}

	if ($args{data} && (ref($args{data}) || '' ) ne 'HASH') {
		croak("Argument 'data' must be a HASH");
	}

	if (exists $args{version} && ($args{version} || '') !~ /^\d+\z/) {
		croak("Argument 'version' must be a number");
	}

	if (exists $args{nonce} && ($args{nonce} || '') !~ /^\d+\z/) {
		croak("Argument 'nonce' must be a number");
	}

	my %object = (
		key => $args{key},
		data => {
			_ctrl => {
				_ser => $serial++,
			},
		},
		version => $args{version} || 1,
	);

	if ($args{data}) {
		$object{data}{_data} = $args{data};
	} else {
		$object{data}{_data}{type} = undef;
	}

	if ($args{nonce}) {
		$object{data}{_ctrl}{_nonce} = $args{nonce};
	}

	return bless \%object, $class;
}

sub parse {
	my ($self, $data) = @_;

	$self->_set_error('');

	unless ($self->_cklen($data, 55)) {
		return 0;
	}

	# Everything after first 51 bytes is what needs to be signed
	my $buff = substr($data, 51);

	my $length = unpack('N', $data);
	$data = substr($data, 4);

	unless ($self->_cklen($data, $length)) {
		return 0;
	}

	my $version = unpack('N', $data);
	$data = substr($data, 4);

	unless ($version == 1) {
		return $self->_set_error("Unknown protocol version '$version'");
	}

	my ($aauth, $check);

	try {
		$data = _table_fromwire(\$data);

		$aauth = $data->{_auth}{hmd5};

		$check = $self->_sign($buff);
	} catch {
		my $err = $_;

		if (UNIVERSAL::isa($err, 'Net::RNDC::Exception')) {
			$self->_set_error($err);
		} else {
			die $err;
		}
	};

	return 0 if $self->error;

	if ($check ne $aauth) {
		return $self->_set_error("Couldn't validate response with provided key\n");
	}

	try {
		$self->{data} = _table_fromwire(\$buff);
	} catch {
		my $err = $_;

		if (UNIVERSAL::isa($err, 'Net::RNDC::Exception')) {
			$self->_set_error($err);
		} else {
			die $err;
		}
	};

	return 0 if $self->error;

	$self->_set_error($self->{data}->{_data}{err});

	return $self->error ? 0 : 1;
}

# Set an error. Uses Net::RNDC::Exception to get file/line number
sub _set_error {
	my ($self, $error) = @_;

	if (!$error) {
		$self->{error} = '';
	} elsif (UNIVERSAL::isa($error, 'Net::RNDC::Exception')) {
		$self->{error} = $error->error;
	} else {
		my $e = Net::RNDC::Exception->new($error);
		$self->{error} = $e->error;
	}

	return 0;
}

# Return error string if any
sub error {
	my ($self) = @_;

	return $self->{error};
}

# Return packet data in binary form
sub data {
	my ($self) = @_;

	$self->_set_error('');

	$self->{data}->{_ctrl}->{_tim} = time;
	$self->{data}->{_ctrl}->{_exp} = time + 60;

	my ($udata, $cksum, $wire);

	try {
		$udata = $self->_unsigned_data;

		$cksum = $self->_sign($udata);

		$wire = _table_towire({
			_auth => {
				hmd5 => $cksum,
			},
		}, 'no_header');
	} catch {
		my $err = $_;

		if (UNIVERSAL::isa($err, 'Net::RNDC::Exception')) {
			$self->_set_error($err);
		} else {
			die $err;
		}
	};

	return if $self->error;

	$wire .= $udata;

	return pack('N', length($wire) + 4) . pack('N', $self->{version}) . $wire;
}

# Return the table of data to be signed
sub _unsigned_data {
	my ($self) = @_;

	return _table_towire($self->{data}, 'no_header');
}

# Sign data with our key, return digest
sub _sign {
	my ($self, $data) = @_;

	my $hmac = Digest::HMAC_MD5->new(decode_base64($self->{key}));

	$hmac->add($data);

	return $hmac->b64digest;
}

# Take a string from binary format and return it
sub _binary_fromwire {
	my ($wire) = @_;

	my $data = $$wire;
	$$wire = '';

	return $data;
}

# Pack a string into its binary representation
sub _binary_towire {
	my ($data) = @_;

	if (!defined $data) {
		$data = 'null';
	}

	return pack('c', ISCCC_CCMSGTYPE_BINARYDATA)
	     . pack('N', length($data))
	     . ($data);
}

# Take a table from binary format and return a hashref
sub _table_fromwire {
	my ($wire) = @_;

	my %table;

	while ($$wire) {
		_cklen_d($$wire, 1);
		my $key_len = unpack('c', $$wire);
		$$wire = substr($$wire, 1);

		_cklen_d($$wire, $key_len);
		my $key = substr($$wire, 0, $key_len);
		$$wire = substr($$wire, $key_len);

		$table{$key} = _value_fromwire($wire);
	}

	return \%table;
}

# Pack a hashref into its binary representation
sub _table_towire {
	my ($data, $no_header) = @_;

	my $table;

	for my $k (sort keys %$data) {
		$table .= pack('c', length($k));
		$table .= $k;
		$table .= _value_towire($data->{$k});
	}

	if ($no_header) {
		return $table;
	} else {
		my $msg_type = pack('c', ISCCC_CCMSGTYPE_TABLE);
		return $msg_type . pack('N', length($table)) . $table;
	}
}

# Take a list from binary representation and return an arrayref
sub _list_fromwire {
	my ($wire) = @_;

	my @list;
	while ($$wire) {
		push @list, _value_fromwire($wire);
	}

	return \@list;
}

# Pack an arrayref into its binary representation
sub _list_towire {
	my ($data) = @_;

	my $msg_type = pack('c', ISCCC_CCMSGTYPE_LIST);
	my $list;

	for my $d (@$data) {
		$list .= _value_towire($d);
	}

	return $msg_type . pack('N', length($list)) . $list;
}

# Take a value, whatever it may be, and unpack it into perl data types
sub _value_fromwire {
	my ($wire) = @_;

	_cklen_d($$wire, 5);

	my $msg_type = unpack('c', $$wire);
	$$wire = substr($$wire, 1);

	my $len = unpack('N', $$wire);
	$$wire = substr($$wire, 4);

	_cklen_d($$wire, $len);
	my $data = substr($$wire, 0, $len);
	$$wire = substr($$wire, $len);

	if ($msg_type == ISCCC_CCMSGTYPE_BINARYDATA) {
		return _binary_fromwire(\$data);
	} elsif ($msg_type == ISCCC_CCMSGTYPE_TABLE) {
		return _table_fromwire(\$data);
	} elsif ($msg_type == ISCCC_CCMSGTYPE_LIST) {
		return _list_fromwire(\$data);
	} else {
		die Net::RNDC::Exception->new(
			"Unknown message type '$msg_type' in _value_fromwire"
		);
	}
}

# Take a perl data structure and pack it into binary format
sub _value_towire {
	my ($data) = @_;

	my $r = ref $data || 'binary';

	if ($r eq 'HASH') {
		return _table_towire($data);
	} elsif ($r eq 'ARRAY') {
		return _list_towire($data);
	} elsif ($r eq 'binary') {
		return _binary_towire($data);
	} else {
		die Net::RNDC::Exception->new(
			"Unknown data type '$r' in _value_towire"
		);
	}
}

# Sets an error and returns 0 if the buff isn't at least $len bytes
# unless ($self->_cklen($buff, $len)) {
#	return 0;
# }
sub _cklen {
#	my ($self, $buff, $len) = @_;

	unless ((length($_[1]) || 0) >= $_[2]) {
		$_[0]->_set_error(Net::RNDC::Exception->new(
			"Unexpected end of data reading buffer. (Expected $_[2] more bytes at least)"
		));

		return 0;
	}

	return 1;
}

# Throws an exception if the buff isn't at least $len bytes
#
# _cklen_d($buff, $len)
sub _cklen_d {
#	my ($buff, $len) = @_;

	unless ((length($_[0]) || 0) >= $_[1]) {
		die Net::RNDC::Exception->new(
			"Unexpected end of data reading buffer. (Expected $_[1] more bytes at least)"
		);
	}
}

1;
__END__

=head1 NAME

Net::RNDC::Packet - RNDC Protocol V1 Packet Parsing and Generation

=head1 VERSION

version 0.003

=head1 SYNOPSIS

To send an RNDC command and get a response:

  use IO::Socket::INET;
  use Net::RNDC::Packet;

  my $buff;
  my $key = 'aabc';

  my $c = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1:953',
  ) or die "Failed to create a socket: $@ ($!)";

  # Send opener packet
  my $pkt = Net::RNDC::Packet->new(
    key => $key,
  );

  $c->send($pkt->data);

  # Read nonce response
  $c->recv($buff, 4096);

  $pkt->parse($buff);

  # Send command request with nonce
  my $nonce = $pkt->{data}->{_ctrl}{_nonce};

  my $cmd = Net::RNDC::Packet->new(
    key => $key,
    nonce => $nonce,
    data => {type => 'status'},
  );

  $c->send($cmd->data);

  # Read final response
  $c->recv($buff, 4096);

  $cmd->parse($buff);

  my $resp = $cmd->{data}{_data}{text} || 'command success';

  print "$resp\n";

=head1 DESCRIPTION

This package provides low-level RNDC V1 protocol parsing and generation. It 
allows full control over the data in the sent/received packets.

Currently this is provided by hacking at C<< $pkt->{data} >>, setter/getter 
methods will be forthcoming.

=head2 Constructor

=head3 new

  my $packet = Net::RNDC::Packet->new(%args);

Arguments:

=over 4

=item *

B<key> - The Base64 encoded HMAC-MD5 key to sign/verify packets with.

=item *

B<data> - A hashref of data to put in the request of the packet. Currently, BIND 
only understand commands in the C<type> key. For example:

  data => { type => 'status' },

=item *

B<nonce> - The nonce data returned from the remote nameserver. Located in the 
parsed packet in the _ctrl section:

  nonce => $packet->{data}->{_ctrl}{_nonce},

=back

=head2 Methods

=head3 data

  my $binary = $packet->data;

Generates a binary representation of the packet, suitable for sending over the 
wire.

=head3 parse

  if ($packet->parse($binary)) { ... }

Parses data from the wire and populates the current packet with the information, 
as well as verifies the data with the provided B<key> that was passed to the 
constructor. Returns 1 on success, 0 on failure. Check L</error> if there's a 
failure.

=head3 error

  my $err = $packet->error;

Returns a string error, if any, after packet parsing or generation failed.

=head1 TODO

=over 4

=item *

Methods for modifying the different data parts of an RNDC message

=back

=head1 SEE ALSO

L<Net::RNDC> - Simple RNDC communication.

L<Net::RNDC::Session> - Manage the 4-packet RNDC session

=head1 AUTHOR

Matthew Horsfall (alh) <WolfSage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

# SMB-Perl library, Copyright (C) 2014-2018 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package SMB::DCERPC;

use strict;
use warnings;

use parent 'SMB';

use bytes;

use SMB::Parser;
use SMB::Packer;

# DCERPC 5.0 protocol

use constant {
	# for bind contexts
	UUID_AS_SRVSVC    => "\xc8\x4f\x32\x4b\x70\x16\xd3\x01\x12\x78\x5a\x47\xbf\x6e\xe1\x88",
	UUID_TS_32BIT_NDR => "\x04\x5d\x88\x8a\xeb\x1c\xc9\x11\x9f\xe8\x08\x00\x2b\x10\x48\x60",
	UUID_TS_64BIT_NDR => "\x33\x05\x71\x71\xba\xbe\x37\x49\x83\x19\xb5\xdb\xef\x9c\xcc\x36",
	UUID_TS_BIND_TIME => "\x2c\x1c\xb7\x6c\x12\x98\x40\x45\x03\x00\x00\x00\x00\x00\x00\x00",
	UUID_TS_NULL      => "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",

	PACKET_TYPE_REQUEST  => 0,
	PACKET_TYPE_RESPONSE => 2,
	PACKET_TYPE_BIND     => 11,
	PACKET_TYPE_BIND_ACK => 12,

	STATE_INITIAL  => 0,
	STATE_BIND     => 1,
	STATE_BIND_ACK => 2,
	STATE_REQUEST  => 3,
	STATE_RESPONSE => 4,
};

our %operation_codes = (
	16 => 'NetShareGetInfo',
);

our %operations = reverse %operation_codes;

sub new ($%) {
	my $class = shift;
	my %options = @_;

	die "No name (service name) in constructor"
		unless defined $options{name};

	return $class->SUPER::new(
		state => STATE_INITIAL,
		current_packet_type => undef,
		current_context_id => undef,
		current_call_id => 1,
		requested_opnum => undef,
		requested_opinfo => {},
		contexts => [],
		parser => SMB::Parser->new,
		packer => SMB::Packer->new,
		%options,
	);
}

sub parse_common ($$$) {
	my $self = shift;
	my $payload = shift;
	my $packet_type = shift;

	my $parser = $self->parser;
	$parser->set($payload);

	my $version_major = $parser->uint8 // '-';
	my $version_minor = $parser->uint8 // '-';
	return $self->err("Got unsupported DCERPC version ($version_major.$version_minor)")
		unless $version_major eq 5 && $version_minor eq 0;

	my $given_packet_type = $parser->uint8 // '-';
	return $self->err("Got DCERPC packet_type $given_packet_type (expected $packet_type)")
		unless $packet_type eq $given_packet_type;
	$self->current_packet_type($packet_type);

	my $packet_flags = $parser->uint8 // '-';
	return $self->err("Got unsupported DCERPC packet_flags ($packet_flags)")
		unless $packet_flags eq 3;

	my $data_representation = $parser->uint32 // '-';
	return $self->err("Got unsupported DCERPC data_representation ($data_representation)")
		unless $data_representation eq 0x10;

	my $len = $parser->uint16;
	my $auth_len = $parser->uint16 // '-';
	return $self->err("Got unsupported DCERPC auth_len ($auth_len)")
		unless $auth_len eq 0;

	my $call_id = $parser->uint32 // '-';
	$self->current_call_id($call_id);

	if ($packet_type == PACKET_TYPE_BIND || $packet_type == PACKET_TYPE_BIND_ACK) {
		$parser->uint16;  # max_xmit_frag
		$parser->uint16;  # max_recv_frag
		$parser->uint32;  # assoc_group
		$self->current_context_id(undef);
		$self->requested_opnum(undef);
	} else {
		$parser->uint32;  # alloc hint
		$self->current_context_id($parser->uint16);
		$self->requested_opnum($parser->uint16);
	}

	return 1;
}

sub pack_common ($$) {
	my $self = shift;
	my $packet_type = shift;

	my $packer = $self->packer;
	$packer->reset;

	$packer
		->mark('dcerpc-start')
		->uint8(5)  # version_major
		->uint8(0)  # version_minor
		->uint8($packet_type)
		->uint8(3)  # packet_flags
		->uint32(0x10)  # data_representation
		->stub('frag-length', 'uint16')
		->uint16(0)  # auth_len
		->uint32($self->current_call_id)
		;

	if ($packet_type == PACKET_TYPE_BIND || $packet_type == PACKET_TYPE_BIND_ACK) {
		$packer->uint16(4280);  # max_xmit_frag
		$packer->uint16(4280);  # max_recv_frag
		$packer->uint32(0x5011);  # assoc_group
	} else {
		$packer->uint32(100);  # alloc hint
		$packer->uint16($self->current_context_id);
		$packer->uint16($self->requested_opnum);
	}

	$self->current_packet_type($packet_type);

	return 1;
}

sub finalize_pack_common ($) {
	my $self = shift;
	my $packet_type = shift;

	my $packer = $self->packer;

	$packer->fill('frag-length', $packer->diff('dcerpc-start'));

	return ($packer->data, SMB::STATUS_SUCCESS);
}

sub error ($$$) {
	my $self = shift;
	my $status = shift;
	my $message = shift;

	$self->err($message);

	return (undef, $status)
		if (caller(1))[3] =~ /::generate_/;
	return $status;
}

sub process_bind_request ($$) {
	my $self = shift;
	my $payload = shift // '';

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_INITIAL on bind_request")
		unless $self->state == STATE_INITIAL;

	return $self->error(SMB::STATUS_INVALID_PARAMETER, "Skipping wrong bind_request packet")
		unless $self->parse_common($payload, PACKET_TYPE_BIND);

	my $parser = $self->parser;

	$self->contexts([]);
	my $num_contexts = $parser->uint32;

	for (0 .. $num_contexts - 1) {
		my $context_id = $parser->uint16;
		return $self->error(SMB::STATUS_INVALID_PARAMETER, "Got context id $context_id, expected $_")
			unless $context_id eq $_;
		my $num = $parser->uint16;
		return $self->error(SMB::STATUS_INVALID_PARAMETER, "Got unexpected num_trans_items ($num)")
			unless $num eq 1;

		my $as_uuid = $parser->bytes(16);
		my $as_version = $parser->uint32;

		my $ts_uuid = $parser->bytes(16);
		my $ts_version = $parser->uint32;

		$self->contexts([@{$self->contexts}, $ts_uuid]);
	}

	$self->state(STATE_BIND);

	return SMB::STATUS_SUCCESS;
}

sub generate_bind_request ($) {
	my $self = shift;

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_INITIAL on bind_response")
		unless $self->state == STATE_INITIAL;

	$self->pack_common(PACKET_TYPE_BIND);

	my $packer = $self->packer;

	$packer->uint32(3);  # num_contexts

	for (0 .. 2) {
		$packer
			->uint16($_)  # context id
			->uint16(1)  # num_trans_items
			->bytes(UUID_AS_SRVSVC)
			->uint32(3)  # as_version
			->bytes($_ == 0 ? UUID_TS_32BIT_NDR : $_ == 1 ? UUID_TS_64BIT_NDR : UUID_TS_BIND_TIME)
			->uint32($_ == 0 ? 2 : 1)  # ts_version
			;
	}

	$self->state(STATE_BIND);

	return $self->finalize_pack_common;
}

sub process_bind_ack_response ($$) {
	my $self = shift;
	my $payload = shift // '';

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_BIND on bind_ack_request")
		unless $self->state == STATE_BIND;

	return $self->error(SMB::STATUS_INVALID_PARAMETER, "Skipping wrong bind_request packet")
		unless $self->parse_common($payload, PACKET_TYPE_BIND_ACK);

	my $parser = $self->parser;

	my $scndry_addr_len = $parser->uint16;
	my $scndry_addr = $parser->bytes($scndry_addr_len);
	$parser->skip(1);

	$self->contexts([]);
	my $num_results = $parser->uint32;

	for (0 .. $num_results - 1) {
		my $ack_result = $parser->uint16;
		my $ack_reason = $parser->uint16;

		my $ts_uuid = $parser->bytes(16);
		my $ts_version = $parser->uint32;

		$self->contexts([@{$self->contexts}, $ts_uuid]);
	}

	$self->state(STATE_BIND_ACK);

	return SMB::STATUS_SUCCESS;
}

sub generate_bind_ack_response ($$) {
	my $self = shift;

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_BIND on bind_ack_response")
		unless $self->state == STATE_BIND;

	$self->pack_common(PACKET_TYPE_BIND_ACK);

	my $packer = $self->packer;

	my $scndry_addr = sprintf "\\PIPE\\%s\0", $self->name;
	$packer->uint16(length($scndry_addr));
	$packer->bytes($scndry_addr);
	$packer->uint8(0);

	my $num_results = @{$self->contexts};
	$packer->uint32($num_results);

	for (0 .. $num_results - 1) {
		my ($ack_result, $ack_reason, $ts_uuid, $ts_version) =
			$self->contexts->[$_] eq UUID_TS_64BIT_NDR
				? (0, 0, UUID_TS_64BIT_NDR, 1) :
			$self->contexts->[$_] eq UUID_TS_BIND_TIME
				? (3, 3, UUID_TS_NULL, 0)
				: (2, 2, UUID_TS_NULL, 0);

		$packer
			->uint16($ack_result)
			->uint16($ack_reason)
			->bytes($ts_uuid)
			->uint32($ts_version)
			;
	}

	$self->state(STATE_BIND_ACK);

	return $self->finalize_pack_common;
}

sub process_rpc_request ($$) {
	my $self = shift;
	my $payload = shift // '';

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_BIND_ACK or STATE_RESPONSE on rpc_request")
		unless $self->state == STATE_BIND_ACK || $self->state == STATE_RESPONSE;

	return $self->error(SMB::STATUS_INVALID_PARAMETER, "Skipping wrong rpc_request packet")
		unless $self->parse_common($payload, PACKET_TYPE_REQUEST);

	my $parser = $self->parser;

	my $opnum = $self->requested_opnum // '-';
	if ($opnum == $operations{NetShareGetInfo}) {
		my $referent_id = $parser->uint64;
		my $max_count = $parser->uint64;
		my $offset = $parser->uint64;
		my $count = $parser->uint64;
		my $server_unc = $parser->skip($offset)->str($count * 2); chop($server_unc);
		$parser->align(0, 8);
		$max_count = $parser->uint64;
		$offset = $parser->uint64;
		$count = $parser->uint64;
		my $share_name = $parser->skip($offset)->str($count * 2); chop($share_name);
		$parser->align(0, 4);
		my $level = $parser->uint32;
		return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported NetShareGetInfo level $level")
			unless $level == 1;
		$self->requested_opinfo({
			referent_id => $referent_id,
			share_name => $share_name,
		});
	}
	else {
		return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported rpc operation $opnum");
	}

	$self->state(STATE_REQUEST);

	return SMB::STATUS_SUCCESS;
}

sub generate_rpc_request ($$%) {
	my $self = shift;
	my $opname = shift // die "No operation name";
	my %params = @_;

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_BIND_ACK or STATE_RESPONSE on rpc_request")
		unless $self->state == STATE_BIND_ACK || $self->state == STATE_RESPONSE;

	my $opnum = $operations{$opname};
	return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported operation $opname on rpc_request")
		unless defined $opnum;
	$self->requested_opnum($opnum);
	$self->current_context_id($params{context_id} // 0);

	$self->pack_common(PACKET_TYPE_REQUEST);

	my $packer = $self->packer;

	if ($opnum == $operations{NetShareGetInfo}) {
		my $referent_id = $params{referent_id} // 0;
		my $server_unc = ($params{server_unc} // '127.0.0.1') . "\0";
		my $share_name = ($params{share_name} // '') . "\0";
		my $len1 = length($server_unc);
		my $len2 = length($share_name);
		$packer
			->uint64($referent_id)
			->uint64($len1)  # max_count
			->uint64(0)      # offset
			->uint64($len1)  # count
			->str($server_unc)
			->align(0, 8)
			->uint64($len2)  # max_count
			->uint64(0)      # offset
			->uint64($len2)  # count
			->str($share_name)
			->align(0, 4)
			->uint32(1)  # level
			;
		$self->requested_opinfo({
			referent_id => $referent_id,
			share_name => $share_name,
		});
	}
	else {
		return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported rpc operation $opnum");
	}

	$self->state(STATE_REQUEST);

	return $self->finalize_pack_common;
}

sub process_rpc_response ($$$) {
	my $self = shift;
	my $payload = shift // '';
	my $retinfo = shift // die;

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_REQUEST on rpc_response")
		unless $self->state == STATE_REQUEST;

	return $self->error(SMB::STATUS_INVALID_PARAMETER, "Skipping wrong rpc_response packet")
		unless $self->parse_common($payload, PACKET_TYPE_RESPONSE);

	my $parser = $self->parser;

	my $opnum = $self->requested_opnum // '-';
	if ($opnum == $operations{NetShareGetInfo}) {
		my $level = $parser->uint32();
		return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported NetShareGetInfo level $level")
			unless $level == 1;
		$parser->skip(4);
		my $referent_id = $parser->uint64;
		$parser->skip(8);  # share_name referent_id
		my $stype = $parser->uint32;
		$parser->skip(4);
		$parser->skip(8);  # comment referent_id
		my $max_count = $parser->uint64;
		my $offset = $parser->uint64;
		my $count = $parser->uint64;
		my $share_name = $parser->skip($offset)->str($count * 2); chop($share_name);
		$parser->align(0, 8);
		$max_count = $parser->uint64;
		$offset = $parser->uint64;
		$count = $parser->uint64;
		my $comment = $parser->skip($offset)->str($count * 2); chop($comment);
		$parser->align(0, 4);
		my $winerror = $parser->uint32;
		%$retinfo = (
			referent_id => $referent_id,
			share_name => $share_name,
			comment => $comment,
		);
	}
	else {
		return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported rpc operation $opnum");
	}

	$self->state(STATE_RESPONSE);

	return SMB::STATUS_SUCCESS;
}

sub generate_rpc_response ($$%) {
	my $self = shift;
	my $opnum = shift // $self->requested_opnum;
	my %params = @_;

	return $self->error(SMB::STATUS_INVALID_SMB, "No STATE_REQUEST on rpc_response")
		unless $self->state == STATE_REQUEST;

	$self->pack_common(PACKET_TYPE_RESPONSE);

	my $packer = $self->packer;

	if ($opnum == $operations{NetShareGetInfo}) {
		my $referent_id = $params{referent_id} // $self->requested_opinfo->{referent_id} // 0;
		my $share_name = ($params{share_name} // $self->requested_opinfo->{share_name} // '') . "\0";
		my $comment = ($params{comment} // '') . "\0";
		my $len1 = length($share_name);
		my $len2 = length($comment);
		$packer
			->uint32(1)             # level
			->skip(4)
			->uint64($referent_id)
			->uint64($referent_id)  # share_name referent_id
			->uint32(0)             # stype
			->skip(4)
			->uint64($referent_id)  # comment referent_id
			->uint64($len1)         # max_count
			->uint64(0)             # offset
			->uint64($len1)         # count
			->str($share_name)
			->align(0, 8)
			->uint64($len2)         # max_count
			->uint64(0)             # offset
			->uint64($len2)         # count
			->str($comment)
			->align(0, 4)
			->uint32(0)             # winerror
			;
	}
	else {
		return $self->error(SMB::STATUS_NOT_IMPLEMENTED, "Unsupported rpc operation $opnum");
	}

	$self->state(STATE_RESPONSE);

	return $self->finalize_pack_common;
}

sub process_packet ($$@) {
	my $self = shift;
	my $payload = shift;

	my $state = $self->state;

	return $self->process_bind_request($payload, @_)
		if $state == STATE_INITIAL;
	return $self->process_bind_ack_response($payload, @_)
		if $state == STATE_BIND;
	return $self->process_rpc_request($payload, @_)
		if $state == STATE_BIND_ACK || $state == STATE_RESPONSE;
	return $self->process_rpc_response($payload, @_)
		if $state == STATE_REQUEST;

	return $self->error(SMB::STATUS_INVALID_SMB, "Invalid internal DCERPC state $state");
}

sub generate_packet ($@) {
	my $self = shift;

	my $state = $self->state;

	return $self->generate_bind_request(@_)
		if $state == STATE_INITIAL;
	return $self->generate_bind_ack_response(@_)
		if $state == STATE_BIND;
	return $self->generate_rpc_request(@_)
		if $state == STATE_BIND_ACK || $state == STATE_RESPONSE;
	return $self->generate_rpc_response(@_)
		if $state == STATE_REQUEST;

	return $self->error(SMB::STATUS_INVALID_SMB, "Invalid internal DCERPC state $state");
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::DCERPC - Minimal support for DCE/RPC protocol (over SMB)

=head1 SYNOPSIS

	use SMB::DCERPC;

	# in server

	# on Create request (file srvsvc)
	$openfile->{dcerpc} = SMB::DCERPC->new(name => 'srvsvc');

	# on Write request (when $openfile->{dcerpc} set)
	$status = $openfile->dcerpc->process_bind_request($request->buffer);

	# on Read request (when $openfile->{dcerpc} set)
	($payload, $status) = $openfile->dcerpc->generate_bind_ack_response;

	# on Ioctl request (when $openfile->{dcerpc} set)
	$openfile->dcerpc->process_rpc_request($request->buffer);
	($payload, $status) = $openfile->dcerpc->generate_rpc_response;


	# in client

	# when sending Create request (file srvsvc)
	$dcerpc = SMB::DCERPC->new(name => 'srvsvc');

	# before sending Write request
	($payload, $status) = $dcerpc->generate_bind_request;

	# after sending Read request
	$dcerpc->process_bind_ack_response($response->buffer)
		if $response->status == SMB::STATUS_SUCCESS;

	# when sending Ioctl request
	($payload, $status) = $dcerpc->generate_rpc_request('NetShareGetInfo', share_name => 'users');
	$dcerpc->process_rpc_response($response->buffer, $rethash);

=head1 ABSTRACT

DCE/RPC is Distributed Computing Environment / Remote Procedure Call.
Used in particular in Windows environment to obtain server or workstation
service information.

SMB may be used as transport for DCE/RPC.

In SMB2, special files srvsvc (for server service) and wkssvc (for
workstation service) are used in special IPC trees to make the calls.
The flow is usually like this:

	Create request (srvsvc)
	Create response
	Write request
		Bind
	Write response
	Read request
	Read response
		Bind_ack
	Ioctl request
		Operation NetShareGetInfo: input
	Ioctl response
		Operation NetShareGetInfo: output
	Close request
	Close response

=head1 DESCRIPTION

This class implement basic DCE/RPC protocol for SMB client and server.

This is implemented as a state machine. A client must call:

	generate_bind_request
	process_bind_ack_response

	generate_rpc_request
	process_rpc_response
	...

or just:

	generate_packet
	process_packet
	...

A server must call:

	process_bind_request
	generate_bind_ack_response

	process_rpc_request
	generate_rpc_response
	...

or just:

	process_packet
	generate_packet
	...

The state is at any moment one of:

	INITIAL
	BIND
	BIND_ACK
	REQUEST
	RESPONSE

This class inherits from L<SMB>, so B<msg>, B<err>, B<mem>, B<dump>,
auto-created field accessor and other methods are available as well.

=head1 METHODS

=over 4

=item new

Class constructor. Creates an instance of SMB::DCERPC.

=item generate_bind_request

For client side. Returns DCERPC buffer for payload.

=item process_bind_request dcerpc_buffer

For server side.

=item generate_bind_ack_response

For server side. Returns DCERPC buffer for payload.

=item process_bind_ack_response dcerpc_buffer

For client side.

=item generate_rpc_request opnum params

For client side. Returns DCERPC buffer for payload.

=item process_rpc_request dcerpc_buffer

For server side.

=item generate_rpc_response [opnum params]

For server side. Returns DCERPC buffer for payload.

=item process_rpc_response dcerpc_buffer rethash

For client side.

=item generate_packet dcerpc_buffer [params]

This is a dispatcher (depending on the current state) to one of:

 generate_bind_request
 generate_bind_ack_response
 generate_rpc_request
 generate_rpc_response

=item process_packet [params]

This is a dispatcher (depending on the current state) to one of:

 process_bind_request
 process_bind_ack_request
 process_rpc_request
 process_rpc_response

=back

=head1 INTERNAL METHODS

=over 4

=item none

None

=back

=head1 FUNCTIONS

No functions are exported, they may be called as SMB::DCERPC::FUNC_NAME.

=over 4

=item none

None

=back

=head1 SEE ALSO

L<SMB>, L<SMB::Server>, L<SMB::Client>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>


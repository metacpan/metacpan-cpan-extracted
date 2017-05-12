# SMB Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
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

package SMB::Connection;

use strict;
use warnings;

use bytes;

use parent 'SMB';

use SMB::Parser;
use SMB::Packer;
use SMB::v1::Commands;
use SMB::v2::Commands;

sub parse_uint8  { $_[0]->parser->uint8;  }
sub parse_uint16 { $_[0]->parser->uint16; }
sub parse_uint32 { $_[0]->parser->uint32; }
sub parse_bytes  { $_[0]->parser->bytes($_[1]); }
sub parse_smb1   { SMB::v1::Commands->parse($_[0]->parser) }
sub parse_smb2   { SMB::v2::Commands->parse($_[0]->parser) }

sub pack_uint8  { $_[0]->packer->uint8($_[1]);  }
sub pack_uint16 { $_[0]->packer->uint16($_[1]); }
sub pack_uint32 { $_[0]->packer->uint32($_[1]); }
sub pack_bytes  { $_[0]->packer->bytes($_[1]); }
sub pack_smb1   { SMB::v1::Commands->pack(shift()->packer, shift, @_) }
sub pack_smb2   { SMB::v2::Commands->pack(shift()->packer, shift, @_) }

sub new ($$$%) {
	my $class = shift;
	my $socket = shift || die "No socket";
	my $id = shift || die "No id";
	my %options = @_;

	my $quiet   = delete $options{quiet}   || 0;
	my $verbose = delete $options{verbose} || 0;

	my $self = $class->SUPER::new(
		%options,
		quiet   => $quiet,
		verbose => $verbose,
		socket  => $socket,
		id      => $id,
		parser  => SMB::Parser->new,
		packer  => SMB::Packer->new,
	);

	unless ($self->disable_log) {
		my $addr_with_port = $self->get_socket_addr;
		my ($id0, $str) = $id =~ /^-(.*)/ ? ($1, 'server') : ($id, 'client');
		$self->{id_str} = "$str #$id0 [$addr_with_port]";
	}

	$self->msg("Connected");

	return $self;
}

sub DESTROY ($) {
	my $self = shift;

	$self->close;
}

sub close ($) {
	my $self = shift;

	my $socket = $self->socket;
	return unless $socket && $socket->opened;

	$self->msg("Disconnected");

	$socket->close;
	$self->socket(undef);
}

sub get_socket_addr ($;$) {
	my $this = shift;
	my $socket = shift || ref($this) && $this->socket || return;

	my $host = $socket->peerhost();
	my $port = $socket->peerport();

	return wantarray ? ($host, $port) : "$host:$port";
}

sub recv_nbss ($) {
	my $self = shift;

	my $socket = $self->socket;
	my $data1;  # NBSS header
	my $data2;  # SMB packet
	my $header_label = 'NetBIOS Session Service header';
	my $len = $socket->read($data1, 4) //
		return $self->err("Read failed: $!");
	if ($len != 4) {
		$self->err("Can't read $header_label (got $len bytes)");
		return;
	}
	my ($packet_type, $packet_flags, $packet_len) = unpack('CCn', $data1);
	if ($packet_type != 0 || $packet_flags > 1) {
		$self->err("Only supported $header_label with type=0 flags=0|1");
		return;
	}
	$packet_len += 1 << 16 if $packet_flags;
	$len = $socket->read($data2, $packet_len) // 0;
	if ($len != $packet_len) {
		$self->err("Can't read full packet (expected $packet_len, got $len bytes)");
		return;
	}

	$self->parser->set($data1 . $data2, 4);
}

sub recv_command ($) {
	my $self = shift;

	$self->recv_nbss
		or return;

	my $smb_num = $self->parse_uint8;
	my $smb_str = $self->parse_bytes(3);
	if ($smb_str ne 'SMB' || $smb_num != 0xff && $smb_num != 0xfe) {
		$self->err("Neither SMB1 nor SMB2 signature found, giving up");
		$self->mem(chr($smb_num) . $smb_str, "Signature");
		return;
	}
	my $is_smb1 = $smb_num == 0xff;
	$self->mem($self->parser->data, "<- SMB Packet")
		if $self->verbose;

	my $command = $is_smb1
		? $self->parse_smb1
		: $self->parse_smb2;

	if ($command) {
		$self->msg("%s", $command->dump);
	} else {
		$self->err("Failed to parse SMB%d packet", $is_smb1 ? 1 : 2);
	}

	return $command;
}

sub send_nbss ($$) {
	my $self = shift;
	my $data = shift;

	$self->mem($data, "-> NetBIOS Packet")
		if $self->verbose;

	if (!$self->socket->write($data, length($data))) {
		$self->err("Can't write full packet");
		return;
	}
}

sub send_command ($$) {
	my $self = shift;
	my $command = shift;

	$self->msg("%s", $command->dump);

	$self->packer->reset;

	$command->is_smb1
		? $self->pack_smb1($command, is_response => 1)
		: $self->pack_smb2($command, is_response => 1);

	$self->send_nbss($self->packer->data);
}

sub log ($$$) {
	my $self = shift;
	my $is_err = shift;
	my $format = shift;
	return if $self->{disable_log};
	$format =~ s/(:?$)/ - $self->{id_str}$1/;
	$self->SUPER::log($is_err, $format, @_);
}

1;

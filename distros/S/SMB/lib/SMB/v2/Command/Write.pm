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

package SMB::v2::Command::Write;

use strict;
use warnings;

use parent 'SMB::v2::Command';

use constant {
	FLAGS_WRITE_THROUGH        => 1,  # SMB 3.*
	FLAGS_WRITE_UNBUFFERED     => 2,  # SMB 3.02

	CHANNEL_NONE               => 0,
	CHANNEL_RDMA_V1            => 1,  # SMB 3.*
	CHANNEL_RDMA_V1_INVALIDATE => 2,  # SMB 3.02
};

sub init ($) {
	$_[0]->set(
		flags           => 0,
		offset          => 0,
		length          => 0,
		channel         => 0,
		remaining_bytes => 0,
		fid             => 0,
		openfile        => undef,
		buffer          => undef,
	)
}

sub parse ($$) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		$parser->uint16;  # reserved
		$self->length($parser->uint32);
		$self->remaining_bytes($parser->uint32);
		$parser->uint16;  # channel info offset
		$parser->uint16;  # channel info length
	} else {
		my $offset = $parser->uint16;
		my $length = $parser->uint32;
		$self->length($length);
		$self->offset($parser->uint64);
		$self->fid($parser->fid2);
		$self->channel($parser->uint32);
		$self->remaining_bytes($parser->uint32);
		$parser->uint16;  # channel info offset
		$parser->uint16;  # channel info length
		$self->flags($parser->uint32);
		$self->buffer($parser->bytes($length));
	}

	return $self;
}

sub pack ($$) {
	my $self = shift;
	my $packer = shift;

	if ($self->is_response) {
		$packer
			->uint16(0)  # reserved
			->uint32($self->length)
			->uint32($self->remaining_bytes)
			->uint16(0)  # channel info offset
			->uint16(0)  # channel info length
		;
	} else {
		my $buffer = $self->buffer // die "No buffer";

		$packer
			->stub('data-offset', 'uint16')
			->uint32(length($buffer))
			->uint64($self->offset)
			->fid2($self->fid || die "No fid set")
			->uint32($self->channel)
			->uint32($self->remaining_bytes)
			->uint16(0)  # channel info offset
			->uint16(0)  # channel info length
			->uint32($self->flags)
			->fill('data-offset', $packer->diff('smb-header'))
			->bytes($self->buffer)
		;
	}
}

1;

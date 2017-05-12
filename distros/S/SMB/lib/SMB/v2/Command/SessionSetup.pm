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

package SMB::v2::Command::SessionSetup;

use strict;
use warnings;

use parent 'SMB::v2::Command';

sub init ($) {
	$_[0]->set(
		flags           => 0,
		security_mode   => 0,
		capabilities    => 0,
		prev_session_id => 0,
		security_buffer => undef,
	)
}

sub parse ($$%) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		$parser->uint16;  # session flags
		my $offset = $parser->uint16;
		my $length = $parser->uint16;
		$self->security_buffer($parser->bytes($length));
	} else {
		$self->flags($parser->uint8);
		$self->security_mode($parser->uint8);
		$self->capabilities($parser->uint32);
		$parser->uint32;  # channel
		my $offset = $parser->uint16;
		my $length = $parser->uint16;
		$self->prev_session_id($parser->uint64);
		$self->security_buffer($parser->bytes($length));
	}

	return $self;
}

sub prepare_response ($) {
	my $self = shift;

	$self->SUPER::prepare_response;

	my $more_processing = $self->security_buffer && length($self->security_buffer) > 70;

	$self->set_status(SMB::STATUS_MORE_PROCESSING_REQUIRED) if $more_processing;

	$self->header->uid(int(rand(999999)) + 1) unless $self->header->uid;
}

sub pack ($$) {
	my $self = shift;
	my $packer = shift;

	my $security_buffer = $self->security_buffer;

	if ($self->is_response) {
		$security_buffer
			or return $self->abort_pack($packer, SMB::STATUS_LOGON_FAILURE);

		$packer
			->uint16(0)  # session flags
			->uint16($packer->diff('smb-header') + 4)
			->uint16(length $security_buffer)
			->bytes ($security_buffer)
		;
	} else {
		$security_buffer
			or die "No security_buffer";

		$packer
			->uint8 ($self->flags)
			->uint8 ($self->security_mode)
			->uint32($self->capabilities)
			->uint32(0)  # channel
			->uint16($packer->diff('smb-header') + 12)
			->uint16(length $security_buffer)
			->uint64($self->prev_session_id)
			->bytes ($security_buffer)
		;
	}
}

1;

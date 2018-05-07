# SMB Perl library, Copyright (C) 2014-2018 Mikhael Goikhman, migo@cpan.org
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

package SMB::v2::Command::Ioctl;

use strict;
use warnings;

use parent 'SMB::v2::Command';

use constant {
	FSCTL_DFS_GET_REFERRALS => 0x00060194,
	FSCTL_PIPE_TRANSCEIVE   => 0x0011c017,
};

sub init ($) {
	$_[0]->set(
		function => 0,
		flags    => 0,
		length   => 0,  # in on request, out on response
		offset   => 0,  # in on request, out on response
		max_size => 0,  # out only
		fid      => 0,
		openfile => undef,
		buffer   => undef,
	)
}

sub parse ($$) {
	my $self = shift;
	my $parser = shift;

	$parser->skip(2);  # unknown
	$self->function($parser->uint32);
	$self->fid($parser->fid2);
	if ($self->is_response) {
		$parser->uint32;                   # in offset, ignore
		$parser->uint32;                   # in length, ignore
		$self->offset($parser->uint32);    # out offset
		$self->length($parser->uint32);    # out length
	} else {
		$self->offset($parser->uint32);    # in offset
		$self->length($parser->uint32);    # in length
		$parser->uint32;                   # in max_size, ignore
		$parser->uint32;                   # out offset, ignore
		$parser->uint32;                   # out length, ignore
		$self->max_size($parser->uint32);  # out max_size
		$self->flags($parser->uint32);
	}
	$self->buffer($parser->reset($self->offset)->bytes($self->length));

	return $self;
}

sub pack ($$) {
	my $self = shift;
	my $packer = shift;

	my $buffer = $self->buffer // die "No buffer";

	$packer
		->skip(2)  # unknown
		->uint32($self->function // FSCTL_PIPE_TRANSCEIVE)
		->fid2($self->fid || die "No fid set")
	;
	if ($self->is_response) {
		$packer
			->uint32(0)                        # in offset
			->uint32(0)                        # in length
			->stub('buffer-offset', 'uint32')  # out offset
			->uint32(length $buffer)           # out length
		;
	} else {
		$packer
			->stub('buffer-offset', 'uint32')  # in offset
			->uint32(length $buffer)           # in length
			->uint32(0)                        # in max_size
			->uint32(0)                        # out offset
			->uint32(0)                        # out length
			->uint32(1024)                     # out max_size
			->uint32($self->flags)
		;
	}
	$packer
		->fill('buffer-offset', $packer->diff('smb-header'))
		->bytes($buffer)
	;
}

1;

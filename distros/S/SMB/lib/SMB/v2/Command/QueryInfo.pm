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

package SMB::v2::Command::QueryInfo;

use strict;
use warnings;

use parent 'SMB::v2::Command';

use constant {
	TYPE_FILE       => 1,
	TYPE_FILESYSTEM => 2,
	TYPE_SECURITY   => 3,
	TYPE_QUOTA      => 4,

	FILE_LEVEL_DIRECTORY       => 1,
	FILE_LEVEL_FULLDIRECTORY   => 2,
	FILE_LEVEL_BOTHDIRECTORY   => 3,
	FILE_LEVEL_BASIC           => 4,
	FILE_LEVEL_STANDARD        => 5,
	FILE_LEVEL_INTERNAL        => 6,
	FILE_LEVEL_EA              => 7,
	FILE_LEVEL_ACCESS          => 8,
	FILE_LEVEL_NAMES           => 12,
	FILE_LEVEL_POSITION        => 14,
	FILE_LEVEL_FULLEA          => 15,
	FILE_LEVEL_MODE            => 16,
	FILE_LEVEL_ALIGNMENT       => 17,
	FILE_LEVEL_ALL             => 18,
	FILE_LEVEL_ALTERNATENAME   => 21,
	FILE_LEVEL_STREAM          => 22,
	FILE_LEVEL_PIPE            => 23,
	FILE_LEVEL_PIPELOCAL       => 24,
	FILE_LEVEL_PIPEREMOTE      => 25,
	FILE_LEVEL_COMPRESSION     => 28,
	FILE_LEVEL_QUOTA           => 32,
	FILE_LEVEL_NETWORKOPEN     => 34,
	FILE_LEVEL_ATTRIBUTETAG    => 35,
	FILE_LEVEL_IDBOTHDIRECTORY => 37,
	FILE_LEVEL_IDFULLDIRECTORY => 38,

	FS_LEVEL_VOLUMEINFORMATION     => 1,
	FS_LEVEL_SIZEINFORMATION       => 3,
	FS_LEVEL_DEVICEINFORMATION     => 4,
	FS_LEVEL_ATTRIBUTEINFORMATION  => 5,
	FS_LEVEL_CONTROLINFORMATION    => 6,
	FS_LEVEL_FULLSIZEINFORMATION   => 7,
	FS_LEVEL_OBJECTIDINFORMATION   => 8,
	FS_LEVEL_SECTORSIZEINFORMATION => 11,
};

sub init ($) {
	$_[0]->set(
		type       => 0,
		level      => 0,
		max_length => 65536,
		additional => 0,
		flags      => 0,
		buffer     => undef,
		fid        => 0,
		openfile   => undef,
		files      => undef,
	)
}

sub parse ($$) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		my $offset = $parser->uint16;
		my $length = $parser->uint32;
		$self->buffer($parser->bytes($length));
	} else {
		$self->type($parser->uint8);
		$self->level($parser->uint8);
		$self->max_length($parser->uint32);
		my $offset = $parser->uint16;
		$parser->skip(2);  # reserved
		my $length = $parser->uint32;
		$self->additional($parser->uint32);
		$self->flags($parser->uint32);
		$self->fid($parser->fid2);
		$self->buffer($parser->bytes($length));
	}

	return $self;
}

sub pack ($$) {
	my $self = shift;
	my $packer = shift;

	my $buffer = $self->buffer;

	if ($self->is_response) {
		$packer
			->uint16($packer->diff('smb-header') + 6)
			->uint32(defined $buffer ? length($buffer) : 0)
			->bytes($buffer // '')
		;
	} else {
		$packer
			->uint8($self->type)
			->uint8($self->level)
			->uint32($self->max_length)
			->uint16($packer->diff('smb-header') + 32)
			->uint16(0)  # reserved
			->uint32(defined $buffer ? length($buffer) : 0)
			->uint32($self->additional)
			->uint32($self->flags)
			->fid2($self->fid || die "No fid set")
			->bytes($buffer // '')
		;
	}
}

1;

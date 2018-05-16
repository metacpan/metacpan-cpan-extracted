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

use SMB::Packer;
use SMB::Time;

our $start_time = time();

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
	FILE_LEVEL_NAME            => 9,
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

my @type_names = (undef, "FILE", "FS", "SECURITY", "QUOTA");

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

sub prepare_info ($%) {
	my $self = shift;
	my %params = @_;

	my $type = $self->type;
	my $level = $self->level;

	my $openfile = $self->openfile
		or return $self->msg("Called prepare_fs_response without openfile");
	my $file = $openfile->file
		or return $self->msg("Called prepare_fs_response without file");

	my $filename = $file->filename // "IPC\$\\$file->{name}";
	my $packer = SMB::Packer->new;

	my $type_name = $type_names[$type] || "UNKNOWN";
	$self->msg("Info $type_name level=$level for $filename")
		unless $params{quiet};

	if ($type == TYPE_FILE) {
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_BASIC) {
			$packer
				->uint64($file->creation_time)
				->uint64($file->last_access_time)
				->uint64($file->last_write_time)
				->uint64($file->change_time)
				->uint32($file->attributes)
				->uint32(0)  # reserved
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_STANDARD) {
			$packer
				->uint64($file->allocation_size)
				->uint64($file->end_of_file)
				->uint32(1)  # number of links
				->uint8($openfile->delete_on_close)  # delete pending
				->uint8($file->is_directory)
				->uint16(0)  # reserved
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_INTERNAL) {
			$packer
				->uint64($file->id)
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_EA) {
			$packer
				->uint32(0)  # ea (external attributes) size
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_ACCESS) {
			$packer
				->uint32(0x00000080)  # access flags (READ ATTRIBUTES)
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_POSITION) {
			$packer
				->uint64(0)  # current byte offset
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_MODE) {
			$packer
				->uint32(0)  # mode
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_ALIGNMENT) {
			$packer
				->uint32(0)  # alignment requirement
			;
		}
		if ($level == FILE_LEVEL_ALL || $level == FILE_LEVEL_NAME) {
			my $filename = $file->name;

			$packer
				->uint32(length($filename) * 2)
				->utf16($filename)
			;
		}

		if ($level == FILE_LEVEL_NETWORKOPEN) {
			$packer
				->uint64($file->creation_time)
				->uint64($file->last_access_time)
				->uint64($file->last_write_time)
				->uint64($file->change_time)
				->uint64($file->allocation_size)
				->uint64($file->end_of_file)
				->uint32($file->attributes)
				->uint32(0)  # reserved
			;
		}

		if ($packer->size == 0) {
			$self->err('Ignoring unsupported FILE level $level, expect problems');
		}
	}
	elsif ($type == TYPE_FILESYSTEM) {
		if ($level == FS_LEVEL_VOLUMEINFORMATION) {
			my $name = "SMB.pm";
			$packer
				->uint64(to_nttime($start_time))  # created time
				->uint32($file->id)  # volume serial number
				->uint32(length($name) * 2)
				->utf16($name)
				->uint16(0x017f)  # reserved
			;
		}
		elsif ($level == FS_LEVEL_ATTRIBUTEINFORMATION) {
			my $fs_type = (split(/\n/, `LANG=C df --output=fstype $filename 2>/dev/null`))[1] || "unknown";
			$packer
				->uint32(0x00007)  # attributes
				->uint32(255)  # max filename length
				->uint32(length($fs_type) * 2)
				->utf16($fs_type)
			;
		}
		elsif ($level == FS_LEVEL_DEVICEINFORMATION) {
			$packer
				->uint32(0x7)  # device type (Disk)
				->uint32(0x20)  # characterictics
			;
		}
		elsif ($level == FS_LEVEL_FULLSIZEINFORMATION) {
			$packer
				->uint64(0x0)  # allocation size
				->uint64(0x0)  # caller free units
				->uint64(0x0)  # actual free units
				->uint32(0x0)  # sectors per unit
				->uint32(0x0)  # bytes per sector
			;
		}
		else {
			$self->err('Ignoring unsupported FS level $level, expect problems');
		}
	}
	else {
		$self->err('Ignoring unsupported INFO type $type, expect problems');
	}

	$self->buffer($packer->data);
}

1;

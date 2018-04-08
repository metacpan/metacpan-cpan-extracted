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

package SMB::v2::Command::SetInfo;

use strict;
use warnings;

use parent 'SMB::v2::Command';

use constant {
	TYPE_FILE       => 1,
	TYPE_FILESYSTEM => 2,
	TYPE_SECURITY   => 3,
	TYPE_QUOTA      => 4,

	FILE_LEVEL_BASIC           => 4,
	FILE_LEVEL_RENAME          => 10,
	FILE_LEVEL_LINK            => 11,
	FILE_LEVEL_DISPOSITION     => 13,
	FILE_LEVEL_POSITION        => 14,
	FILE_LEVEL_FULLEA          => 15,
	FILE_LEVEL_MODE            => 16,
	FILE_LEVEL_ALLOCATION      => 19,
	FILE_LEVEL_ENDOFFILE       => 20,
	FILE_LEVEL_PIPE            => 23,
	FILE_LEVEL_QUOTA           => 32,
	FILE_LEVEL_VALIDDATALENGTH => 39,
	FILE_LEVEL_SHORTNAME       => 40,

	FS_LEVEL_CONTROLINFORMATION  => 6,
	FS_LEVEL_OBJECTIDINFORMATION => 8,

	FILE_DISPOSITION_DELETE_ON_CLOSE => 0x1,
};

sub init ($) {
	$_[0]->set(
		type       => 0,
		level      => 0,
		additional => 0,
		buffer     => undef,
		fid        => 0,
		openfile   => undef,
	)
}

sub parse ($$) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		# empty
	} else {
		$self->type($parser->uint8);
		$self->level($parser->uint8);
		my $length = $parser->uint32;
		my $offset = $parser->uint16;
		$parser->skip(2);  # reserved
		$self->additional($parser->uint32);
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
		# empty
	} else {
		$packer
			->uint8($self->type)
			->uint8($self->level)
			->uint32(defined $buffer ? length($buffer) : 0)
			->uint16($packer->diff('smb-header') + 32 - 8)
			->uint16(0)  # reserved
			->uint32($self->additional)
			->fid2($self->fid || die "No fid set")
			->bytes($buffer // '')
		;
	}
}

sub requested_rename_info ($) {
	my $self = shift;

	return unless
		$self->type == TYPE_FILE &&
		$self->level == FILE_LEVEL_RENAME;

	my $parser = SMB::Parser->new($self->buffer);
	my $replace = $parser->uint8;
	$parser->skip(7);  # reserved
	$parser->skip(8);  # root dir handle
	my $new_name_len = $parser->uint16;
	$parser->skip(2);  # reserved
	my $new_name = $parser->str($new_name_len);

	return {
		new_name => $new_name,
		replace  => $replace,
	};
}

sub requested_delete_on_close ($) {
	my $self = shift;

	return
		$self->type == TYPE_FILE &&
		$self->level == FILE_LEVEL_DISPOSITION &&
		ord($self->buffer) & FILE_DISPOSITION_DELETE_ON_CLOSE ? 1 : 0;
}

1;

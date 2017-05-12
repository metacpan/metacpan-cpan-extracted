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

package SMB::v2::Command::Close;

use strict;
use warnings;

use parent 'SMB::v2::Command';

use constant {
	FLAGS_POSTQUERY_ATTRIB => 1,
};

sub init ($) {
	$_[0]->set(
		flags    => 0,
		fid      => 0,
		openfile => undef,
	)
}

sub parse ($$) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		my $openfile = $self->openfile;
		my $file = $openfile && $openfile->file;

		$self->flags($parser->uint16);
		$parser->uint32;  # reserved
		my @values = ((map { $parser->uint64 } 1 .. 6), $parser->uint32);
		$file->update(@values) if $file;
	} else {
		$self->flags($parser->uint16);
		$parser->uint32;  # reserved
		$self->fid($parser->fid2);
	}

	return $self;
}

sub pack ($$) {
	my $self = shift;
	my $packer = shift;

	if ($self->is_response) {
		my $openfile = $self->openfile;
		my $file = $openfile && $openfile->file;

		return $self->abort_pack($packer, SMB::STATUS_FILE_CLOSED)
			unless $file && $file->exists;

		my $skip_attr = !($self->flags & FLAGS_POSTQUERY_ATTRIB);

		$packer
			->uint16($self->flags)
			->uint32(0)  # reserved
			->uint64($skip_attr ? 0 : $file->creation_time)
			->uint64($skip_attr ? 0 : $file->last_access_time)
			->uint64($skip_attr ? 0 : $file->last_write_time)
			->uint64($skip_attr ? 0 : $file->change_time)
			->uint64($skip_attr ? 0 : $file->allocation_size)
			->uint64($skip_attr ? 0 : $file->end_of_file)
			->uint32($skip_attr ? 0 : $file->attributes)
		;
	} else {
		$packer
			->uint16($self->flags)
			->uint32(0)  # reserved
			->fid2($self->fid || die "No fid set")
		;
	}
}

1;

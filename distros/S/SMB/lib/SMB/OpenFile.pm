# SMB-Perl library, Copyright (C) 2014 Mikhael Goikhman, migo@cpan.org
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

package SMB::OpenFile;

use strict;
use warnings;

use parent 'SMB';

use Fcntl 'SEEK_SET';
use SMB::File;

sub new ($$$$%) {
	my $class = shift;
	my $file = shift || die "No file\n";
	my $handle = shift || 0;
	my $action = shift || SMB::File::ACTION_NONE;
	my %options = @_;

	my $self = $class->SUPER::new(
		file    => $file,
		handle  => $handle,
		action  => $action,
		last_index => 0,
		%options,
	);

	return $self;
}

sub close ($) {
	my $self = shift;

	$self->file->delete_openfile($self);
}

sub read ($%) {
	my $self = shift;
	my %params = @_;  # length offset minlen remain

	my $fh = $self->{handle} or return;
	sysseek($fh, $params{offset} || 0, SEEK_SET) or return;

	my $length = $params{length} // return;
	my $minlen = $params{minlen} || 0;

	my $buffer;
	sysread($fh, $buffer, $length) // return;
	return unless length($buffer) < $minlen;

	return $buffer;
}

1;

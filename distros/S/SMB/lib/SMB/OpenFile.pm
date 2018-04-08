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
		delete_on_close => 0,
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

	my $fh = $self->{handle} or return '';
	sysseek($fh, $params{offset} || 0, SEEK_SET) or return;

	my $length = $params{length} // return;
	my $minlen = $params{minlen} || 0;

	my $buffer;
	sysread($fh, $buffer, $length) // return;
	return unless length($buffer) < $minlen;

	return $buffer;
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::OpenFile - A state of opening local or remote file for SMB

=head1 SYNOPSIS

	use SMB::File;

	# for server, on Create request
	my $file = SMB::File->new(
		name => $create_request->file_name,
		share_root => $tree->root,
		is_ipc => $tree->is_ipc,
	);
	my $openfile = $file->supersede;  # or: create, open, overwrite etc
	$openfile->close;
	$openfile = $file->open_by_disposition(SMB::File::DISPOSITION_OPEN_IF);


	# for client, on Create response
	my $file = $create_response->openfile->file;

=head1 DESCRIPTION

This class implements an SMB open-file abstraction, mainly for a server.

This class inherits from L<SMB>, so B<msg>, B<err>, B<mem>, B<dump>,
auto-created field accessor and other methods are available as well.

=head1 METHODS

=over 4

=item new FILE HANDLE ACTION [OPTIONS]

Class constructor. Creates an instance of SMB::OpenFile.

FILE is an L<SMB::File> object being open, HANDLE is a unix file
descriptor, and ACTION is one of I<ACTION_OPENED>, I<ACTION_CREATED> and
so on, see L<SMB::File>.

=item close

Performs the opposite operation to the constructor.

Internally this is implemented by calling L<SMB::File> B<delete_openfile>,
and the constructor is normally called from L<SMB::File> B<add_openfile>.

=item read OPTIONS

For openfile corresponding to the local file (having the actual HANDLE)
performs the read operation according to the OPTIONS hash values.

The OPTIONS keys are I<offset>, I<length> and I<minlen>. Option I<length>
is mandatory (may be 0), the others are optional and default to 0.

On success, the buffer of I<length> or less bytes being read starting
from I<offset> is returned. On error (or if lesser than I<minlen> bytes
were read from file HANDLE), undef is returned.

=back

=head1 SEE ALSO

L<SMB::File>, L<SMB::Server>, L<SMB>.

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>


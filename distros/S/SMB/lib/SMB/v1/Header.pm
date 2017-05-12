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

package SMB::v1::Header;

use strict;
use warnings;

use parent 'SMB::Header';

use constant {
	# the command is a response, otherwise a request
	FLAGS_RESPONSE => 0x80,
	# client supports signing, server forces signing
	FLAGS2_SECURITY_SIGNATURE => 0x0004,
	# client desires compression, server agrees to compress
	FLAGS2_COMPRESSED => 0x0008,
	# client supports signing, server forces signing
	FLAGS2_SECURITY_SIGNATURE_REQUIRED => 0x0010,
	# extended security negotiation is supported
	FLAGS2_EXTENDED_SECURITY_NEGOTIATION => 0x0800,
	# string are in Unicode (UTF-16LE) encoding
	FLAGS2_UNICODE => 0x8000,
	# NT statuses used
	FLAGS2_NT_STATUS => 0x4000,
};

sub new ($%) {
	my $class = shift;
	my %options = @_;

	return $class->SUPER::new(
		pid       => delete $options{pid} || 0,
		flags2    => delete $options{flags2} || 0,
		%options,
	);
}

sub is_response ($) {
	my $self = shift;

	return $self->flags & FLAGS_RESPONSE ? 1 : 0;
}

sub is_signed ($) {
	my $self = shift;
	my $signature = $self->signature;

	return ref($signature) eq 'ARRAY' && @$signature == 8 &&
		(join('', $signature) ne "\0" x 8) &&
		($self->flags2 & FLAGS2_SECURITY_SIGNATURE) != 0;
}

1;

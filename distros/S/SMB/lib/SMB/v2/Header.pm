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

package SMB::v2::Header;

use strict;
use warnings;

use parent 'SMB::Header';

use constant {
	# the command is a response, otherwise a request
	FLAGS_RESPONSE => 0x1,
	# the command is asynchronous
	FLAGS_ASYNC_COMMAND => 0x2,
	# the command is continued, part of the chain
	FLAGS_CHAINED => 0x4,
	# the command is signed */
	FLAGS_SIGNED => 0x8,
	# DFS resolution is required
	FLAGS_DFS => 0x10000000,
};

sub new ($%) {
	my $class = shift;
	my %options = @_;

	return $class->SUPER::new(
		aid           => delete $options{aid} || 0,
		credits       => delete $options{credits} || 0,
		credit_charge => delete $options{credit_charge} || ($options{code} ? 1 : 0),
		struct_size   => delete $options{struct_size} || 2,
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

	return ref($signature) eq 'ARRAY' && @$signature == 16 &&
		(join('', $signature) ne "\0" x 16) &&
		($self->flags & FLAGS_SIGNED) != 0;
}

1;

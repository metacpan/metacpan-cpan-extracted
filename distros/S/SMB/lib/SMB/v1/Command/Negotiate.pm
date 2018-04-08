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

package SMB::v1::Command::Negotiate;

use strict;
use warnings;

use parent 'SMB::v1::Command';

sub init ($) {
	$_[0]->set(
		dialect_names => [],
	);
}

sub parse ($$%) {
	my $self = shift;
	my $parser = shift;

	if ($self->is_response) {
		# unsupported
	} else {
		$parser->skip(1);  # word count
		$self->dialect_names([
			map { substr($_, 1) } grep { substr($_, 0, 1) eq "\x02" }
				split("\x00", $parser->bytes($parser->uint16))
		]);
	}

	return $self;
}

sub supports_smb_dialect ($$) {
	my $self = shift;
	my $dialect0 = shift;

	for (@{$self->dialect_names}) {
		return 1 if /^SMB (\d+)\.[0?](\d{2}|\?\?)/ && ($1 << 8 + ($2 eq '??' ? 0 : $2)) > $dialect0;
	}

	return 0;
}

1;

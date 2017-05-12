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

package SMB::Header;

use strict;
use warnings;

use parent 'SMB';

sub new ($%) {
	my $class = shift;
	my %options = @_;

	$options{code} // die "No code for $class";
	$options{mid}  // die "No message id for $class";

	return $class->SUPER::new(
		%options,
		code      => $options{code},
		status    => $options{status} || 0,
		uid       => $options{uid} || 0,
		tid       => $options{tid} || 0,
		mid       => $options{mid},
		flags     => $options{flags} || 0,
		signature => $options{signature},
	);
}

sub is_response ($) {
	die "Pure virtual method is called";
}

sub is_signed ($) {
	die "Pure virtual method is called";
}

1;

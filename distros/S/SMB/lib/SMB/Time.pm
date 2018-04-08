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

package SMB::Time;

use strict;
use warnings;

# bigint conflicts with Time::HiRes::time, prefer to lose precision for now
#use if (1 << 32 == 1), 'bigint';  # support native uint64 on 32-bit platforms

use Exporter 'import';
our @EXPORT = qw(from_nttime to_nttime);

my $nttime_factor = 10_000_000;
my $nttime_offset = 11_644_473_600;

sub from_nttime ($) {
	my $nttime = shift || return 0;

	return $nttime / $nttime_factor - $nttime_offset;
}

sub to_nttime ($) {
	my $time = shift || return 0;

	return ($time + $nttime_offset) * $nttime_factor;
}

1;

__END__
# ----------------------------------------------------------------------------

=head1 NAME

SMB::Time - Functions to convert between UNIX time and SMB time

=head1 SYNOPSIS

	use SMB::Time qw(from_nttime to_nttime);

	print scalar localtime(from_nttime(1.305e+17)), "\n";

	use Time::HiRes qw(time);  # enhance native time(), optional

	print to_nttime(time), "\n";

=head1 ABSTRACT

Time values in L<SMB> follow the NTFS time convention.
This module helps to convert between NT time and UNIX time.

NT time is number of 100-nanoseconds since 1601-01-01 00:00:00 UTC.

UNIX time is number of seconds since 1970-01-01 00:00:00 UTC.

=head1 EXPORTED FUNCTIONS

By default, functions B<from_nttime> and B<to_nttime> are exported using the standard L<Exporter> mechanism.

=over 4

=item from_nttime NTTIME

Returns NT time (64-bit unsigned integer) given UNIX time (32-bit unsigned integer).

=item to_nttime UNIXTIME

Returns UNIX time (32-bit unsigned integer) given NT time (64-bit unsigned integer).

=back

=head1 AUTHOR

Mikhael Goikhman <migo@cpan.org>


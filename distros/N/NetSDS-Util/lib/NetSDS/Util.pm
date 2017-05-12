#===============================================================================
#
#         FILE:  Util.pm
#
#  DESCRIPTION:  NetSDS utilities
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  24.07.2009 09:38:14 UTC
#===============================================================================
=head1 NAME

NetSDS::Util - supplementary NetSDS packages

=head1 SYNOPSIS

	use NetSDS::Util::Convert;
	use NetSDS::Util::String;

	my $trim_str = str_trim(" Some string with leading and trailing   ");

=head1 DESCRIPTION

C<NetSDS::Util> modules contains functions useful for everyday tasks.

=over

=item B<NetSDS::Util::Convert> - data format conversions

=item B<NetSDS::Util::DateTime> - processing date and time

=item B<NetSDS::Util::File> - work with files and catalogs

=item B<NetSDS::Util::Spreadsheet> - processing spreadsheet files

=item B<NetSDS::Util::Misc> - miscelaneous routines

=item B<NetSDS::Util::String> - text and binary strings processing

=item B<NetSDS::Util::Struct> - data structures conversion

=item B<NetSDS::Util::Translit> - transliteration

=item B<NetSDS::Util::Types> - work with data types


=back

=cut

package NetSDS::Util;

use 5.8.0;
use strict;
use warnings;

use version; our $VERSION = "1.045";

1;

__END__


=head1 BUGS

Unknown yet

=head1 SEE ALSO

L<NetSDS::Util::Convert>

L<NetSDS::Util::DateTime>

L<NetSDS::Util::File>

L<NetSDS::Util::Spreadsheet>

L<NetSDS::Util::Misc>

L<NetSDS::Util::String>

L<NetSDS::Util::Struct>,

L<NetSDS::Util::Translit>

L<NetSDS::Util::Types>

=head1 TODO

Implement functional tests.

=head1 AUTHOR

Valentyn Solomko <pere@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

Yana Kornienko <yana@netstyle.com.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Michael Bochkaryov

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut



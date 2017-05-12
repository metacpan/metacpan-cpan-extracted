#===============================================================================
#
#         FILE:  Const.pm
#
#  DESCRIPTION:  NetSDS common constants
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  05.05.2008 16:40:51 EEST
#===============================================================================

=head1 NAME

NetSDS::Const - common NetSDS constants

=head1 SYNOPSIS

	use NetSDS::Const;

	print "XML encoding is " . XML_ENCODING;

	print "Week contains " . INTERVAL_WEEK . " seconds";

=head1 DESCRIPTION

This module provides most common constants like default encoding and language, time intervals, etc.

=cut

package NetSDS::Const;

use 5.8.0;
use strict;
use warnings;

use base 'Exporter';

use version; our $VERSION = '1.301';

our @EXPORT = qw(
  LANG_BE
  LANG_DE
  LANG_EN
  LANG_RU
  LANG_UK
  DEFAULT_ENCODING
  DEFAULT_LANG
  XML_VERSION
  XML_ENCODING
  INTERVAL_MINUTE
  INTERVAL_HOUR
  INTERVAL_DAY
  INTERVAL_WEEK
);

=head1 LANGUAGE AND ENCODINGS

=over

=item B<LANG_BE> - C<be>

=item B<LANG_DE> - C<de>

=item B<LANG_EN> - C<en>

=item B<LANG_RU> - C<ru>

=item B<LANG_UK> - C<uk>

=item B<DEFAULT_LANG> - C<ru> in current version

=item B<DEFAULT_ENCODING> - C<UTF8>

=back

=cut

use constant LANG_BE => 'be';
use constant LANG_DE => 'de';
use constant LANG_EN => 'en';
use constant LANG_RU => 'ru';
use constant LANG_UK => 'uk';

use constant DEFAULT_LANG     => LANG_RU;
use constant DEFAULT_ENCODING => 'UTF8';

=head1 XML CONSTANTS

=over

=item B<XML_VERSION> - C<1.0>

=item B<XML_ENCODING> - C<UTF-8>

=back

=cut

use constant XML_VERSION  => '1.0';
use constant XML_ENCODING => 'UTF-8';

=head1 TIME INTERVALS

=over

=item B<INTERVAL_MINUTE> - 60 seconds

=item B<INTERVAL_HOUR> - 3600 seconds

=item B<INTERVAL_DAY> - 86400 seconds

=item B<INTERVAL_WEEK> - 604800 seconds

=back

=cut

use constant INTERVAL_MINUTE => 60;
use constant INTERVAL_HOUR   => 3600;
use constant INTERVAL_DAY    => 86400;
use constant INTERVAL_WEEK   => 604800;

1;

__END__

=head1 AUTHOR

Valentyn Solomko <val@pere.org.ua>

Michael Bochkaryov <misha@rattler.kiev.ua>

=head1 LICENSE

Copyright (C) 2008-2009 Net Style Ltd.

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



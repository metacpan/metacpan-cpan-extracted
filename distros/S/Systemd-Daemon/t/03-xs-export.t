#!perl -T
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/03-xs-export.t
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Systemd-Daemon.
#
#   perl-Systemd-Daemon is free software: you can redistribute it and/or modify it under the terms
#   of the GNU General Public License as published by the Free Software Foundation, either version
#   3 of the License, or (at your option) any later version.
#
#   perl-Systemd-Daemon is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Systemd-Daemon. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use autodie ':all';
use lib 't/lib';

use Test::More;
use TestSD;

my $pkg    = __PACKAGE__;
my $module = 'Systemd::Daemon::XS';

# No functions should be imported implicitly.
test_import_none( $pkg, $module );

# Import few functions explicitly.
test_import_some( $pkg, $module, qw{ sd_notify sd_pid_notify sd_is_fifo $SD_ALERT } );

# Import all using ":all" tag.
test_import_all( $pkg, $module );

done_testing;
exit( 0 );

# end of file #

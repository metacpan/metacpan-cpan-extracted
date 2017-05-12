#!perl -T
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/04-xs-func.t
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

use POSIX qw{};
use Test::More;

use TestSD;

my $pkg    = __PACKAGE__;
my $module = 'Systemd::Daemon::XS';

use Systemd::Daemon::XS;     # Export nothing.

delete( $ENV{ NOTIFY_SOCKET } );
delete( $ENV{ LISTEN_PID } );
delete( $ENV{ LISTEN_FDS } );

foreach my $sym ( @Symbols ) {
    test_symbol( $module, $sym );
};

done_testing;
exit( 0 );

# end of file #

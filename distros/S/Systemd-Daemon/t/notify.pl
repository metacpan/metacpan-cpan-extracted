#!perl -T
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/notify.pl
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
use autodie ':all';

use FindBin qw{};
use Getopt::Long qw{};

use blib "$FindBin::Bin/../blib";
use Systemd::Daemon qw{ -hard notify };

my $sleep = 0;
my $exit  = 0;
Getopt::Long::GetOptions(
    'sleep=i'   => \$sleep,
    'exit=i'    => \$exit,
) or die;
@ARGV % 2 == 0 or die;

#   `join` or `map` applied to `@ARGV` cause Perl diagnostics:
#       Insecure dependency in eval_sv() while running with -T switch
my @args = @ARGV;
my $notify = 'notify( ';
while ( @args ) {
    $notify .= shift( @args ) . ' => ' . shift( @args ) . ( @args ? ', ' : ' ' );
}; # while
$notify .= ')';
my $rc = notify( @ARGV );
$notify .= ' => ' . $rc;
STDERR->print( "# ", $notify, "\n" );

sleep( $sleep );
exit( $exit );

# end of file #

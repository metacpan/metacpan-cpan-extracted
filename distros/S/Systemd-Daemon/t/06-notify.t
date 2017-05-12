#!perl -T
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/06-notify.t
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
use autodie;

use Config;
use File::Which;
use FindBin;
use IPC::Run3;
use Path::Tiny qw{ path tempfile };
use Systemd::Daemon qw{ notify sd_booted };
use Test::More;

my $perl = $Config{ perlpath };
    # Accordingly to <http://wiki.cpantesters.org/wiki/CPANAuthorNotes>, `$^X` is unreliable.
my $sep = $Config{ path_sep };
my $notify = "$FindBin::Bin/notify.pl";

my $systemctl = which( 'systemctl' );
if ( not defined( $systemctl ) and not $ENV{ AUTHOR_TESTING } ) {
    plan skip_all => "no 'systemctl' found in PATH";
};

#
#   Helper function: run systemctl program, check its status and grab its output.
#

sub systemctl(@) {
    my $allowed = ( @_ > 0 and ref( $_[ 0 ] ) ) ? shift( @_ ) : [ 0 ];
    my @cmd = ( $systemctl, '--user', @_ );
    my ( @stdout, @stderr );
    diag( "\$ " . join( ' ', @cmd ) );
    local $ENV{ PATH } = '';
    IPC::Run3::run3( \@cmd, \undef, \@stdout, \@stderr );
    my $signal = $? & 0xFE;
    my $status = ( $? >> 8 ) & 0xFF;
    if ( $signal or $status or 1 ) {
        diag( ". $_" ) for @stdout;
        diag( "! $_" ) for @stderr;
        diag( "(signal: $signal, status: $status)" );
    };
    if ( $signal ) {
        die "Program '$systemctl' died with signal $signal\n";
    };
    if ( not grep( { $status == $_ } @$allowed ) ) {
        die "Program '$systemctl' exited with status $status";
    };
    return join( '', @stdout );
}; # sub systemctl

#
#   Check systemd version.
#

diag( "sd_booted: " . sd_booted() );
my $version = systemctl( '--version' );
$version =~ m{^systemd (\d+)\n} or die "Cannot parse systemd version\n";
$version = $1;
#   Systemd reads user units from `$XDG_RUNTIME_DIR/systemd/user` starting from version 217.
if ( $version < 217 ) {
    plan skip_all => "systemd $version is too old for the test";
};

#
#   Check XDG_RUNTIME_DIR environment variable.
#

defined( $ENV{ XDG_RUNTIME_DIR } ) or die "XDG_RUNTIME_DIR is not defined\n";
$ENV{ XDG_RUNTIME_DIR } ne ""      or die "XDG_RUNTIME_DIR is empty\n";
-e $ENV{ XDG_RUNTIME_DIR }         or die "XDG_RUNTIME_DIR='$ENV{ XDG_RUNTIME_DIR }' directory does not exist\n";
-d $ENV{ XDG_RUNTIME_DIR }         or die "XDG_RUNTIME_DIR='$ENV{ XDG_RUNTIME_DIR }' is not a directory\n";
diag( "XDG_RUNTIME_DIR=$ENV{ XDG_RUNTIME_DIR }" );

#
#   Create directory for test unit.
#

$ENV{ XDG_RUNTIME_DIR } =~ m{\A(/.*)\z} or die;     # Make -T happy.
my $systemd = "$1/systemd";
-e $systemd or die "Directory '$systemd' does not exist\n";
-d $systemd or die "'$systemd' is not a directory\n";
if ( not -d "$systemd/user" ) {
    mkdir( "$systemd/user" );
}; # if

#
#   Create file for test unit.
#

my $unit = tempfile(
    "systemd-notify-XXXXXX",
    SUFFIX  => '.service',
    DIR     => "$ENV{ XDG_RUNTIME_DIR }/systemd/user",
);
diag( "unit is $unit" );
my $service = $unit->basename;

# --------------------------------------------------------------------------------------------------

sub test(@) {
    my ( $args, @expected ) = @_;
    diag( "===== Test: $args =====" );
    #   We are going to run a Perl script as a service. However, there is a problem: the service
    #   will be started by `systemd`, and so, will not inherit our environment variables. If user
    #   have local perl library, it likely will not be accessible. So we have to explicitly
    #   pass each directory listed in `PERL5LIB` to the perl as a series of `-I` options.
    my $I = join( ' ', map( "\"-I$_\"", grep( $_ ne '', split( $sep, $ENV{ PERL5LIB } ) ) ) );
    $unit->append(
        { truncate => 1 },
        "[Unit]\n" .
        "Description  = perl-Systemd-Daemon test service\n" .
        "[Service]\n" .
        "Type         = simple\n" .
        "NotifyAccess = main\n" .
        "ExecStart    = $perl -T $I $notify $args\n" .
        "\n"
    );
    systemctl( 'daemon-reload' );
    systemctl( 'cat', $service );

    systemctl( 'start', $service );
    sleep( 1 );     # Let daemon start and notify systemd.
    my $status = systemctl( [ 0, 3 ], 'status', $service );
        # If service failed, "systemctl status" returns 3. Accept it.
    foreach my $expected ( @expected ) {
        like( $status, $expected );
    }; # foreach $expected
    #   In case of "STOPPING=1", systemd will not stop service immediately but will wait noticeable
    #   time. To avoid long delay, let us kill service first, then stop it.
    systemctl( 'kill', $service );
    systemctl( 'stop', $service );
}; # sub test

#
#   Now we are ready for actual tests.
#

test(
    "--sleep 1000000 RELOADING 10",             # Any true value is suitable, not just "1".
    qr{^\s*Active:\s*reloading \(reload\)}m,
);

test(
    "--sleep 1000000 READY true",               # Any true value is suitable, not only "1".
    qr{^\s*Active:\s*active \(running\)}m,
);

test(
    "--sleep 1000000 STOPPING yes",             # Any true value is suitable, not only "1".
    qr{^\s*Active:\s*deactivating\b}m,
);

test(
    "--sleep 1000000 STATUS Foo",
    qr{^\s*Active:\s*active \(running\)}m,
    qr{^\s*Status:\s*"Foo"\s*$}m,
);

test(
    "--sleep 1000000 STATUS 47%%",
    qr{^\s*Status:\s*"47%"\s*$}m,
);
    #   "STATUS 47%" will be written to systemd unit file. In unit files, `%` has a special meaning,
    #   so we have to double it.

test(
    "--exit 55 ERRNO 2 STATUS Oops",
    qr{^\s*Active:\s*failed\b}m,
    qr{^\s*Status:\s*"Oops"\s*}m,
    qr{^\s*Error:\s*2\b}m,
);

done_testing;
exit( 0 );

# end of file #

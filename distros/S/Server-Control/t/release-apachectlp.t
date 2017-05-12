#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;
use Capture::Tiny qw(tee tee_merged capture_merged);
use File::Temp qw(tempdir);
use File::Which;
use IPC::System::Simple qw(run);
use Server::Control::Util qw(kill_my_children);
use Server::Control::t::Apache;
use strict;
use warnings;

if ( !scalar( which('httpd') ) ) {
    plan( skip_all => 'no httpd in PATH' );
}
plan( tests => 17 );

# How to pick this w/o possibly conflicting...
my $port        = 15432;
my $server_root = tempdir( 'Server-Control-XXXX', DIR => '/tmp', CLEANUP => 1 );
my $ctl         = Server::Control::t::Apache->create_ctl( $port, $server_root );

sub try {
    my ( $opts, $expected, $desc ) = @_;

    my ( $output, $error ) = tee {
        my $full_cmd = "bin/apachectlp $opts";
        run($full_cmd);
    };
    like( $output, $expected, "$opts $desc" );
}

sub try_error {
    my ( $opts, $expected ) = @_;

    my $output = capture_merged {
        my $full_cmd = "bin/apachectlp $opts";
        system($full_cmd);
    };
    like( $output, $expected, "apachectlp $opts" );
}

eval {
    my $conf_file = $ctl->conf_file;

    try( "-f $conf_file -k stop", qr/is not running/, 'when not running' );
    try(
        "-d $server_root -k start",
        qr/is now running .* and listening to port/,
        'when not running'
    );
    try( "-f $conf_file -k start", qr/already running/, 'when running' );
    try(
        "-d $server_root -k ping",
        qr/is running .* and listening to port/,
        'when running'
    );

    try(
        "-f $conf_file -k ping --name foo --pid-file $server_root/logs/my-httpd.pid --port $port",
        qr/server 'foo' is running .* and listening to port/,
        'ping when running, specify name, pid file and port on command line'
    );

    try( "--server-root $server_root -k stop", qr/stopped/, 'when running' );
    try( "--conf-file $conf_file -k ping", qr/not running/,
        'when not running' );
    try(
        "-f $conf_file -k ping --class +Server::Control::Test::PoliteApache",
        qr/is not running, sir/,
        'when not running'
    );

    try_error( "-h",     qr/usage:/i, '-h' );
    try_error( "--help", qr/usage:/i, '--help' );

    try_error( "-d /does/not/exist -k ping", qr{no such server root '/does/not/exist'} );
    try_error( "-f /does/not/exist -k ping", qr{no such conf file '/does/not/exist'} );
    try_error( "-f $conf_file", qr/must specify -k|--action.*usage:/si );
    try_error( "-f $conf_file -k ping --no-parse-config", qr/no port specified/si );
    try_error( "-k start",      qr/must specify one of -d or -f.*usage/si );
    try_error( "-k bleah -f $conf_file",
        qr/invalid action 'bleah'/s );
    try_error(
        "-k ping -f $conf_file --bad-option",
        qr/Unknown option: bad-option.*usage:/si
    );
};
my $error = $@;
cleanup();
die $error if $error;

sub cleanup {
    eval { $ctl->stop() };
    kill_my_children();
}

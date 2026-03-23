# -*- perl -*-
#
#   Test that proto => 'unix' works when clients are defined.
#   Reproduces https://github.com/cpan-authors/Net-Daemon/issues/1
#
require 5.004;
use strict;

use IO::Socket        ();
use Config            ();
use Net::Daemon::Test ();

if ( $^O eq "MSWin32" ) {
    print "1..0\n";
    exit 0;
}

my $CONFIG_FILE = "t/unix_clients_config";
my $SOCK_PATH   = "mysock_clients";

my $config = q/
    { 'mode' => 'fork',
      'timeout' => 60,
      'clients' => [ { 'mask' => '.*', 'accept' => 1 } ]
    }/;

if ( !open( CF, ">$CONFIG_FILE" ) || !( print CF $config ) || !close(CF) ) {
    die "Error while creating config file $CONFIG_FILE: $!";
}

my $numTests = 3;

my ( $handle, $port ) = Net::Daemon::Test->Child(
    $numTests,
    $^X,        '-Iblib/lib', '-Iblib/arch',
    't/server', "--localpath=$SOCK_PATH",
    '--mode=fork',
    '--configfile', $CONFIG_FILE,
    '--timeout', 60
);

print "Connecting to Unix socket with clients defined...\n";
my $fh = IO::Socket::UNIX->new( 'Peer' => $port );
if ( !$fh ) {
    print "Failed to connect: " . ( $@ || $! ) . "\n";
}
printf( "%s 1\n", $fh ? "ok" : "not ok" );

# Test data exchange to verify client was accepted
my $success = 0;
if ($fh) {
    eval {
        $fh->print("5\n") && $fh->flush() or die "write failed";
        my $line = $fh->getline();
        die "read failed" unless defined $line;
        $success = 1 if $line =~ /10/;
    };
}
printf( "%s 2\n", $success ? "ok" : "not ok" );

printf( "%s 3\n", ( $fh && $fh->close() ) ? "ok" : "not ok" );

END {
    if ($handle) { $handle->Terminate() }
    unlink "ndtest.prt"  if -e "ndtest.prt";
    unlink $SOCK_PATH    if -e $SOCK_PATH;
    unlink $CONFIG_FILE  if -e $CONFIG_FILE;
    exit 0;
}

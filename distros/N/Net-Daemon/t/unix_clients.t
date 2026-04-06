# -*- perl -*-
#
#   Test that proto => 'unix' works when clients are defined.
#   Reproduces https://github.com/cpan-authors/Net-Daemon/issues/1
#

use strict;
use warnings;

use IO::Socket        ();
use Net::Daemon::Test ();
use Test::More;

if ( $^O eq "MSWin32" ) {
    plan skip_all => 'Unix sockets are not available on Windows';
}

plan tests => 3;

my $CONFIG_FILE = "t/unix_clients_config";
my $SOCK_PATH   = "mysock_clients";

my $config = q/
    { 'mode' => 'fork',
      'timeout' => 60,
      'clients' => [ { 'mask' => '.*', 'accept' => 1 } ]
    }/;

open( my $cf, '>', $CONFIG_FILE ) or die "Error creating $CONFIG_FILE: $!";
print $cf $config or die "Error writing $CONFIG_FILE: $!";
close($cf) or die "Error closing $CONFIG_FILE: $!";

my ( $handle, $port ) = Net::Daemon::Test->Child(
    undef,
    $^X,        '-Iblib/lib', '-Iblib/arch',
    't/server', "--localpath=$SOCK_PATH",
    '--mode=fork',
    '--configfile', $CONFIG_FILE,
    '--timeout', 60
);

my $fh = IO::Socket::UNIX->new( 'Peer' => $port );
ok( $fh, 'connect to unix socket with clients defined' ) or diag("Connect failed: " . ( $@ || $! ));

my $success = 0;
if ($fh) {
    eval {
        $fh->print("5\n") && $fh->flush() or die "write failed";
        my $line = $fh->getline();
        die "read failed" unless defined $line;
        $success = 1 if $line =~ /10/;
    };
}
ok( $success, 'data exchange through unix socket' ) or diag($@);

ok( ( $fh && $fh->close() ), 'connection close' );

END {
    if ($handle)              { $handle->Terminate() }
    if ( -f "ndtest.prt" )    { unlink "ndtest.prt" }
    if ( -e $SOCK_PATH )      { unlink $SOCK_PATH }
    if ( -f $CONFIG_FILE )    { unlink $CONFIG_FILE }
}

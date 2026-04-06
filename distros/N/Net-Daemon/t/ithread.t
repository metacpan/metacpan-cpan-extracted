# -*- perl -*-

use strict;
use warnings;

use Config;
use IO::Socket        ();
use Net::Daemon::Test ();
use Test::More;

if ( !$Config{useithreads} ) {
    plan skip_all => 'This test requires a perl with working ithreads.';
}

# Perl ithreads on Windows use DuplicateHandle() to clone file descriptors
# into new threads.  MSDN explicitly states that DuplicateHandle must not
# be used with Winsock SOCKETs — WSADuplicateSocket() is required instead.
# Since Perl core does not use WSADuplicateSocket, accepted client sockets
# get corrupted when cloned into handler threads, causing sporadic
# "Invalid argument" errors during socket I/O.  This is a Perl core
# limitation, not a Net::Daemon bug.  See #19, #30.
if ( $^O eq "MSWin32" ) {
    print "1..0 # SKIP Perl ithreads on Windows cannot safely duplicate Winsock sockets (DuplicateHandle vs WSADuplicateSocket)\n";
    exit 0;
}

require threads;
plan tests => 5;

my ( $handle, $port ) = Net::Daemon::Test->Child( undef, $^X, 't/server', '--timeout', 20, '--mode=ithreads' );

my $fh = IO::Socket::INET->new(
    'PeerAddr' => '127.0.0.1',
    'PeerPort' => $port
);
ok( $fh, 'first connection' );
ok( $fh->close(), 'first connection close' );

$fh = IO::Socket::INET->new(
    'PeerAddr' => '127.0.0.1',
    'PeerPort' => $port
);
ok( $fh, 'second connection' );

my $exchange_ok = eval {
    for ( my $i = 0; $i < 20; $i++ ) {
        if ( !$fh->print("$i\n") || !$fh->flush() ) {
            die "Error while writing $i: " . $fh->error() . " ($!)";
        }
        my $line = $fh->getline();
        die "Error while reading $i: " . $fh->error() . " ($!)"
          unless defined($line);
        die "Result error: Expected " . ( $i * 2 ) . ", got $line"
          unless ( $line =~ /(\d+)/ && $1 == $i * 2 );
    }
    1;
};
ok( $exchange_ok, 'multiplier exchange (20 rounds)' ) or diag($@);
ok( $fh->close(), 'second connection close' );

END {
    if ($handle)           { $handle->Terminate() }
    if ( -f "ndtest.prt" ) { unlink "ndtest.prt" }
}

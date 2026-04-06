# -*- perl -*-

use strict;
use warnings;

use IO::Socket        ();
use Net::Daemon::Test ();
use Test::More;

my $ok;
eval {
    if ( $^O ne "MSWin32" ) {
        my $pid = fork();
        if ( defined($pid) ) {
            if ( !$pid ) { exit 0; }    # Child
        }
        waitpid( $pid, 0 );
        $ok = 1;
    }
};
if ( !$ok ) {
    plan skip_all => 'This test requires a system with working forks.';
}

plan tests => 5;

my ( $handle, $port );
if (@ARGV) {
    $port = shift @ARGV;
}
else {
    ( $handle, $port ) = Net::Daemon::Test->Child(
        undef,
        $^X, '-Iblib/lib',
        '-Iblib/arch',
        't/server', '--mode=fork',
        '--debug', '--timeout', 60
    );
}

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
            die "Error while writing number $i: " . $fh->error() . " ($!)";
        }
        my ($line) = $fh->getline();
        if ( !defined($line) ) {
            die "Error while reading number $i: " . $fh->error() . " ($!)";
        }
        if ( $line !~ /(\d+)/ || $1 != $i * 2 ) {
            die "Wrong response, expected " . ( $i * 2 ) . ", got $line";
        }
    }
    1;
};
ok( $exchange_ok, 'multiplier exchange (20 rounds)' ) or diag($@);
ok( $fh->close(), 'second connection close' );

END {
    if ($handle)           { $handle->Terminate() }
    if ( -f "ndtest.prt" ) { unlink "ndtest.prt" }
}

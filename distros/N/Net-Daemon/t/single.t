# -*- perl -*-

use strict;
use warnings;

use IO::Socket        ();
use Net::Daemon::Test ();
use Test::More tests => 5;

my ( $handle, $port );
if (@ARGV) {
    $port = shift @ARGV;
}
else {
    ( $handle, $port ) = Net::Daemon::Test->Child(
        undef,
        $^X,         '-Iblib/lib', '-Iblib/arch',
        't/server',  '--mode=single',
        '--timeout', 60
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

my $ok = $fh ? 1 : 0;
for ( my $i = 0; $ok && $i < 20; $i++ ) {
    if ( !$fh->print("$i\n") || !$fh->flush() ) { $ok = 0; last; }
    my ($line) = $fh->getline();
    if ( !defined($line) ) { $ok = 0; last; }
    if ( $line !~ /(\d+)/ || $1 != $i * 2 ) { $ok = 0; last; }
}
ok( $ok, 'multiplier exchange (20 rounds)' );
ok( $fh->close(), 'second connection close' );

END {
    if ($handle)           { $handle->Terminate() }
    if ( -f "ndtest.prt" ) { unlink "ndtest.prt" }
}

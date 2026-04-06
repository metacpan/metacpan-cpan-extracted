# -*- perl -*-

use strict;
use warnings;

use IO::Socket        ();
use Net::Daemon::Test ();
use Test::More tests => 6;

my ( $handle, $port ) = Net::Daemon::Test->Child(
    undef,
    $^X,        '-Iblib/lib', '-Iblib/arch',
    't/server', '--mode=single',
    '--loop-timeout=2',
    '--timeout', 60
);

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
        my ($line) = $fh->getline();
        if ( !defined($line) ) {
            die "Error while reading $i: " . $fh->error() . " ($!)";
        }
        if ( $line !~ /(\d+)/ || $1 != $i * 2 ) {
            die "Wrong response, expected " . ( $i * 2 ) . ", got $line";
        }
    }
    1;
};
ok( $exchange_ok, 'multiplier exchange (20 rounds)' ) or diag($@);
ok( $fh->close(), 'second connection close' );

my $loop_ok = 0;
for ( my $i = 0; $i < 30; $i++ ) {
    if ( open( my $cnt_fh, '<', 'ndtest.cnt' ) ) {
        my $num = <$cnt_fh>;
        close($cnt_fh);
        if ( defined($num) && $num eq "10\n" ) {
            $loop_ok = 1;
            last;
        }
    }
    sleep 1;
}
ok( $loop_ok, 'loop counter reached 10' );

END {
    if ($handle)            { $handle->Terminate() }
    if ( -f "ndtest.prt" )  { unlink "ndtest.prt" }
    if ( -f "ndtest.cnt" )  { unlink "ndtest.cnt" }
}

# -*- perl -*-

use strict;
use warnings;

use IO::Socket        ();
use Net::Daemon::Test ();
use Test::More;

if ( $^O eq "MSWin32" ) {
    plan skip_all => 'Unix sockets not available on MSWin32.';
}

plan tests => 5;

my ( $handle, $port ) = Net::Daemon::Test->Child(
    undef,
    $^X,        '-Iblib/lib', '-Iblib/arch',
    't/server', '--localpath=mysock',
    '--mode=fork',
    '--timeout', 60
);

my $fh = IO::Socket::UNIX->new( 'Peer' => $port );
ok( $fh, 'first connection' );
ok( $fh->close(), 'first connection close' );

$fh = IO::Socket::UNIX->new( 'Peer' => $port );
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
    if ($handle) { $handle->Terminate() }
    unlink "ndtest.prt" if -e "ndtest.prt";
    unlink "mysock"     if -e "mysock";
}

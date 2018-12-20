#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use File::Temp;
use Socket;

use Protocol::DBus::Address ();

use Protocol::DBus::Connect ();

my $dir = File::Temp::tempdir( CLEANUP => 1 );
my $path = File::Spec->catfile( $dir, 'socket' );

socket my $s, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;
my $addr = Socket::pack_sockaddr_un($path);
bind $s, $addr;

listen( $s, 1 );

alarm 30;

my $pid = fork or do {
    my $ok = eval {
        accept( my $new, $s );
        syswrite $new, 'q';
    };
    sleep;
    exit;
};

close $s;

my ($addr_obj) = Protocol::DBus::Address::parse("unix:path=$path");

my $cln = Protocol::DBus::Connect::create_socket($addr_obj);

isa_ok( $cln, 'GLOB', 'create_socket() creates a filehandle' );

SKIP: {
    my $peername = getpeername($cln);

    skip "Your OS ($^O) doesn’t report getpeername() … ?", 1 if !$peername;

    my $peerpath = Socket::unpack_sockaddr_un($peername);

    $peerpath =~ tr<\0><>d;

    is(
        $peerpath,
        $path,
        '… and the socket is to where we expect',
    );
}

sysread $cln, my $buf, 1;

is(
    $buf,
    'q',
    '… and a piece of data is transferred as expected',
);

kill 'QUIT', $pid;

done_testing();

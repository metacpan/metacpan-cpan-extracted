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

my $s = _create_server($path);

alarm 30;

my $pid = fork or do {
    my $ok = eval {
        accept( my $new, $s );
        syswrite $new, 'q';
    };

    exit;
};

close $s;

my ($addr_obj) = Protocol::DBus::Address::parse("unix:path=$path");

my ($cln, $bin_addr, $human_addr) = Protocol::DBus::Connect::create_socket($addr_obj);

isa_ok( $cln, 'GLOB', 'create_socket() creates a filehandle' );

ok(
    connect($cln, $bin_addr),
    'address can be connect()ed to',
);

SKIP: {
    my $peername = getpeername($cln);

    skip "Your OS ($^O) doesn’t report getpeername() … ?", 1 if !$peername;

    # Accommodate https://rt.cpan.org/Public/Bug/Display.html?id=135262
    my $need_len = length Socket::pack_sockaddr_un('hi');
    $peername = pack "a$need_len", $peername;

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

done_testing();

#----------------------------------------------------------------------

sub _create_server {
    my ($path) = @_;

    socket my $s, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;
    my $addr = Socket::pack_sockaddr_un($path);
    bind $s, $addr;

    listen( $s, 1 );

    return $s;
}

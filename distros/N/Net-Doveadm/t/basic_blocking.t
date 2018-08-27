#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use File::Temp;
use Socket;
use Time::HiRes;

use IO::Framed;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $sockaddr = Socket::pack_sockaddr_un("$dir/socket");

my $LF = "\x0a";

$SIG{'CHLD'} = 'IGNORE';
fork or do {
    my $ok = eval {
        socket my $srv, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;

        bind $srv, $sockaddr;

        listen $srv, 2;

        do { open my $wfh, '>', "$dir/listening" };

        accept( my $cln, $srv );
        close $srv;

        my $line = readline $cln;

        syswrite( $cln, "+$LF" );

        my $req = readline $cln;

        syswrite( $cln, $req . "+$LF" );

        1;
    };

    warn if $@;

    exit( $ok ? 0 : 1 );
};

use_ok('Net::Doveadm');

Time::HiRes::sleep(0.1) while !-e "$dir/listening";

socket my $socket, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;

connect $socket, $sockaddr;

$socket->blocking(0);

my $io = IO::Framed->new( $socket );

my $doveadm = Net::Doveadm->new(
    io => $io,
);

$doveadm->send(
    username => 'some_user',
    command => [ 'name', 'arg1', 'arg2' ],
    flags => [ 'verbose', 'debug' ],
);

my $resp_ar;

{
    last if $resp_ar = $doveadm->receive();
    redo;
}

cmp_deeply(
    $resp_ar,
    [ ignore(), 'some_user', 'name', 'arg1', 'arg2' ],
    'response as expected',
);

done_testing();

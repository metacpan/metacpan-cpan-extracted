#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Deep;

use File::Temp;
use Socket;

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
        diag "$$: $line";

        syswrite( $cln, "+$LF" );

        diag "$$: reading command from client";
        my $req = readline $cln;
        diag "$$: got from client: $req";

        substr( $req, 0, 0, "\t" );
        substr( $req, -1, 0, "\t" );

        syswrite( $cln, $req . "+$LF" );

        1;
    };

    warn if $@;

    exit( $ok ? 0 : 1 );
};

use_ok('Net::Doveadm');

sleep 1 while !-e "$dir/listening";

socket my $socket, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;

connect $socket, $sockaddr;

$socket->blocking(0);

my $io = IO::Framed->new( $socket )->enable_write_queue();

my $doveadm = Net::Doveadm->new(
    io => $io,
);

$doveadm->send(
    username => 'some_user',
    command => [ 'name', 'arg1', 'arg2' ],
    flags => [ 'verbose', 'debug' ],
);

vec( my $rin, fileno($socket), 1 ) = 1;

my $resp_ar;

{
    diag "flushing …";
    $io->flush_write_queue();

    diag "waiting …";
    select( my $rout = $rin, undef, undef, 30 );

    last if $resp_ar = $doveadm->receive();
    redo;
}

cmp_deeply(
    $resp_ar,
    [ q<>, ignore(), 'some_user', 'name', 'arg1', 'arg2', q<> ],
    'command as given, plus empty fields before/after',
) or diag explain $resp_ar;

done_testing();

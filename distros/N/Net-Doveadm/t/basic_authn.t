#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Deep;

use File::Temp;
use Socket;
use Time::HiRes ();

use IO::Framed;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

my $sockaddr = Socket::pack_sockaddr_un("$dir/socket");

my $LF = "\x0a";

my ($un, $pw) = ('doveadm', 'secret');

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
        diag "$$ got: $line";

        syswrite( $cln, "-$LF" );

        my $authn = readline $cln;
        diag "$$: got authn: $authn\n";

        if ($authn ne "PLAIN\tAGRvdmVhZG0Ac2VjcmV0$LF") {
            syswrite( $cln, "-$LF" );
            exit;
        }

        syswrite( $cln, "+$LF" );

        diag "$$: reading command from client";
        my $req = readline $cln;
        diag "$$: got from client: $req";

        syswrite( $cln, $req . "+$LF" );

        1;
    };

    warn if $@;

    exit( $ok ? 0 : 1 );
};

use_ok('Net::Doveadm');

$Net::Doveadm::DEBUG = 1;

Time::HiRes::sleep(0.1) while !-e "$dir/listening";

socket my $socket, Socket::AF_UNIX(), Socket::SOCK_STREAM(), 0;

connect $socket, $sockaddr;

$socket->blocking(0);

my $io = IO::Framed->new( $socket )->enable_write_queue();

vec( my $rin, fileno($socket), 1 ) = 1;

#----------------------------------------------------------------------

my $doveadm = Net::Doveadm->new(
    io => $io,
    username => $un,
    password => $pw,
);

$doveadm->send(
    username => 'some_user',
    command => [ 'name', 'arg1', 'arg2' ],
    flags => [ 'verbose', 'debug' ],
);

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
    [ ignore(), 'some_user', 'name', 'arg1', 'arg2' ],
    'response as expected',
);

done_testing();

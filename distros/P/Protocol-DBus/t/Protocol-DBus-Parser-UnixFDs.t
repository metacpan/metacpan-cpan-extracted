#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Socket;
use Socket::MsgHdr ();

use_ok('Protocol::DBus::Parser::UnixFDs');

if (Socket->can('SCM_RIGHTS')) {
    pipe my ($r, $w);

    socketpair my $yin, my $yang, Socket::AF_UNIX, Socket::SOCK_STREAM, 0;

    my $msg = Socket::MsgHdr->new( buf => "\0" );
    $msg->cmsghdr(
        Socket::SOL_SOCKET(), Socket::SCM_RIGHTS(),
        pack( "I!*", fileno($r), fileno($w) ),
    );

    Socket::MsgHdr::sendmsg($yin, $msg);

    my $rmsg = Socket::MsgHdr->new( buflen => 1 );
    $rmsg->cmsghdr( 0, 0, pack "I!I!" );

    Socket::MsgHdr::recvmsg($yang, $rmsg);

    diag "got message";

    my ($r2, $w2) = Protocol::DBus::Parser::UnixFDs::extract_from_msghdr($rmsg);

    syswrite $w, "Hello1";
    sysread( $r2, my $got1, 512 );

    is( $got1, 'Hello1', 'write original, read dupe' );

    syswrite $w2, "Hello2";
    sysread( $r, my $got2, 512 );

    is( $got2, 'Hello2', 'write dupe, read original' );
}

done_testing();

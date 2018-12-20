#!/usr/bin/perl

use strict;
use warnings;
use autodie;

use Socket;

{
    package Socket;
    use constant LOCAL_PEERCRED => 1;
    use constant LOCAL_PEERPID => 2;
}

use Socket::MsgHdr;

use File::Temp;

my $dir = File::Temp::tempdir( CLEANUP => 1 );

socket( my $srv, Socket::AF_UNIX, Socket::SOCK_STREAM, 0 );
my $addr = Socket::pack_sockaddr_un( "$dir/socket" );
bind( $srv, $addr );

listen( $srv, 45 );

my $cpid = fork or do {
    socket( my $cln, Socket::AF_UNIX, Socket::SOCK_STREAM, 0 );
    connect( $cln, $addr );

    syswrite( $cln, "1" );
    close $cln;

    sleep;

    exit;
};

accept( my $to_cln, $srv );

print "OS: $^O$/";

my @get_sockopts = (
    [ Socket::SOL_SOCKET() => 'SO_PEERCRED' ],
    [ 0 => 'LOCAL_PEEREID' ],
    [ 0 => 'LOCAL_PEERCRED' ],
    [ 0 => 'LOCAL_PEERPID' ],
);
for my $sopt (@get_sockopts) {
    my ($sol, $sopt) = @$sopt;

    my $num;
    if ( eval { $num = Socket->can($sopt)->(); 1 } ) {
        my $out = eval { getsockopt $to_cln, $sol, $num };

        if (defined $out) {
            printf "$sopt: %v.02x\n", $out;
        }
        else {
            warn "getsockopt($sopt): $@";
        }
    }
    else {
        warn "$sopt: $@";
    }
}

my @set_sockopts = (
    [ Socket::SOL_SOCKET() => 'SO_PASSCRED' ],
    [ 0 => 'LOCAL_CREDS' ],
    [ 0 => 'LOCAL_OCREDS' ],
);
for my $sopt (@set_sockopts) {
    my ($sol, $sopt) = @$sopt;

    my $num;
    if ( eval { $num = Socket->can($sopt)->(); 1 } ) {
        my $ok = eval { setsockopt $to_cln, $sol, $num, 1 };

        if (defined $ok) {
            print "$sopt: set OK\n";
        }
        else {
            warn "setsockopt($sopt): $@";
        }
    }
    else {
        warn "$sopt: $@";
    }
}

my $msg = Socket::MsgHdr->new( buflen => 1, controllen => 512 );

Socket::MsgHdr::recvmsg( $to_cln, $msg ) or die "recvmsg(): $!";

use Data::Dumper;
$Data::Dumper::Useqq = 1;

print Dumper [ cmsghdr => $msg->cmsghdr() ];

kill 'TERM', $cpid;

1;

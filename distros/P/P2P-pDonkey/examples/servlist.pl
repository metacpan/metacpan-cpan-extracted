#! /usr/bin/perl -w
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Tie::IxHash;
use Tie::RefHash;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Util ':all';
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::Met ':server';
use ServBase;

my ($debug, $dump) = (1, 0);

my $user = makeClientInfo(0, 4662, 'Muxer', 60);

my $servers = readServerMet('ss.met') or die "Can't read file with server list!\n";
#my $servers = {idAddr(addr2ip('176.16.4.244'),4661) => makeServerDesc(addr2ip('176.16.4.244'), 4661) };
#my $servers = {idAddr(addr2ip('217.128.63.252'),4661) => makeServerDesc(addr2ip('217.128.63.252'), 4661) };
#my $servers = {idAddr(addr2ip('80.130.53.117'),4661) => makeServerDesc(addr2ip('80.130.53.117'), 4661) };

my @procTable;
$procTable[PT_SERVERLIST]   = \&processServerList;
$procTable[PT_SERVERINFO]   = \&processServerInfo;
$procTable[PT_SERVERSTATUS] = \&processServerStatus;

my $server = new ServBase(ProxyAddr => '192.168.3.2', ProxyPort => 8080,
                          ProcTable => \@procTable,
                          OnConnect => \&OnConnect,
                          Dump => $dump);

my $IN;
$IN = IO::Handle->new_from_fd(fileno(STDIN), 'r');
$IN->blocking(0);
#$IN->autoflush(1);
$server->watch($IN);

$SIG{INT} = sub { 
    writeServerMet('ss.met',  $servers); 
    exit;
};

foreach my $s (values %$servers) {
    $server->Connect(ip2addr($s->{IP}), $s->{Port}) || warn "Connect: $!";;
}
#$server->Connect('176.16.4.244', 4661) || warn "Connect: $!";
$server->MainLoop() || die "Can't start server: $!\n";

exit;

sub OnConnect {
    my ($conn) = @_;
    $conn->{InfoCnt} = 3;
    $server->Queue($conn, PT_HELLO, $user);
    $server->Queue($conn, PT_GETSERVERLIST, '');
}

sub processServerStatus {
    my ($conn, $nusers, $nfiles) = @_;
    my $sinfo = $servers->{idAddr($conn)};
    $sinfo or die "Internal error";
    $sinfo->{Meta}->{users} = makeMeta(TT_UNDEFINED, $nusers, 'users', VT_INTEGER);
    $sinfo->{Meta}->{files} = makeMeta(TT_UNDEFINED, $nfiles, 'files', VT_INTEGER);

    $conn->{InfoCnt}--;
    $server->Disconnect($conn->{Socket}) unless $conn->{InfoCnt};
}

sub processServerInfo {
    my ($conn, $d) = @_;
    my $m = $d->{Meta};
    if ($m) {
        my $sinfo = $servers->{idAddr($conn)};
        $sinfo or die "Internal error";
        $sinfo->{Meta}->{Name} = $m->{Name} if ($m->{Name});
        $sinfo->{Meta}->{Description} = $m->{Description} if ($m->{Description});
    }

    $conn->{InfoCnt}--;
    $server->Disconnect($conn->{Socket}) unless $conn->{InfoCnt};
}

sub processServerList {
    my ($conn, $d) = @_;
    my ($ip, $port);

    my $nservnew = 0;
    while (@$d) {
        $ip   = shift @$d;
        $port = shift @$d;
        next if $servers->{idAddr($ip, $port)};
        $nservnew++;
        $servers->{idAddr($ip, $port)} = makeServerDesc($ip, $port);
        $server->Connect(ip2addr($ip), $port) || warn "Connect: $!";
    }
    print "$nservnew new servers\n";

    $conn->{InfoCnt}--;
    $server->Disconnect($conn->{Socket}) unless $conn->{InfoCnt};
}

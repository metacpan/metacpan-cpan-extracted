#! /usr/bin/perl -w
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use IO::Socket;
use Sys::Hostname;
use P2P::pDonkey::Meta qw( :tags makeMeta idAddr );
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::Met ':server';
use P2P::pDonkey::Util ':all';
use Data::Hexdumper;

#use ServBase;

my ($debug, $dump) = (0, 0);
my $hostname = hostname();

my $servers = readServerMet('ss.met') or die "Can't read 'ss.met'!\n";
#my $servers = {'176.16.4.244:4661' => makeServerDesc(addr2ip('176.16.4.244'), 4661) };
#my $servers = {'176.16.5.33:4661' => makeServerDesc(addr2ip('176.16.5.33'), 4661) };

my $localport = 5000;

my $udpsock = new IO::Socket::INET(
        Proto => 'udp', 
        Reuse => 1, 
        LocalPort => $localport)
    || die "can't open udp socket: $@\n";

my $request = packUDPHeader() . packBody(PT_UDP_GETSERVERLIST); 
#$request = packUDPHeader() . packBody(PT_UDP_GETSOURCES, '12bcb48689b4508f326a2b31b105dd9f');
#$request = packUDPHeader() . packBody(PT_UDP_CBREQUEST, addr2ip('176.16.5.33'), 4661, 1);
#$request = packUDPHeader() . packBody(PT_UDP_SERVERSTATUSREQ, 123456);
#$request = packUDPHeader() . packBody(PT_UDP_NEWSERVER, 12345, 444);
#$request = packUDPHeader() . packBody(PT_UDP_GETSERVERLIST);
#my %searchq = (Type => ST_NAME, Value => 'met');
#my $request = packUDPHeader() . packBody(PT_UDP_SEARCHFILE, \%searchq);
#print hexdump(data => $request);

#RequestServList(unpack('L', gethostbyname('176.16.4.244')), 4661+4);
#RequestServList(unpack('L', gethostbyname('176.16.5.33')), 4661+4);
#for my $kk (0 .. 10) {
#    RequestServList(unpack('L', gethostbyname('176.16.4.244')), 4661+$kk);
#}
foreach my $s (values %$servers) {
    RequestServList($s->{IP}, $s->{Port});
}

$SIG{INT} = sub { 
    writeServerMet('ss.met',  $servers); 
    exit;
};

my ($response, $peer);
while (1) {
    defined($peer = $udpsock->recv($response, 20000, 0)) or next;

    my ($port, $addr) = sockaddr_in($peer);
    $addr = inet_ntoa($addr);
    
    my ($h, $pt, $len);
    if (length $response <= SZ_UDP_HEADER) {
        warn "$addr:$port: too small packet\n";
        next;
    }
    
    my $off = 0;
    if (!unpackUDPHeader($response, $off)) {
        warn "$addr:$port: incorrect header tag\n";
        next;
    }

    # unpack server list
#    print hexdump(data => $response);
    my @res = unpackBody(\$pt, $response, $off);
    if ($pt != PT_UDP_SERVERLIST) {
        warn "$addr:$port: got packet '", PacketTagName($pt), "'\n";
#        print join(" ", @res), "\n";
#        print join(" ", @{$res[1]}), "\n";
        next;
    }
    if (!@res) {
        warn "$addr:$port: incorrect packet data\n";
        next;
    }
    my ($addrl) = @res;

    # all ok, process server list
    my $nservnew = 0;
    while (@$addrl) {
        my ($meta);
        my ($sip, $sport) = (shift @$addrl, shift, @$addrl);
        next if $meta = $servers->{idAddr($sip, $sport)};
        $nservnew++;
        $servers->{idAddr($sip, $sport)} = makeServerDesc($sip, $sport);
        RequestServList($sip, $sport);
    }
    print "$addr:$port: $nservnew new servers\n";
#    $nserv += $nservnew;
}
die "EXIT: $! ::: $@\n";
exit;

sub RequestServList {
    my ($portaddr, $ip, $port);
    while (@_) {
        $ip = shift;
        $port = shift;
        $portaddr = sockaddr_in($port+4, pack('L', $ip));
        $udpsock->send($request, 0, $portaddr)
            or die "can't send to ", ip2addr($ip), ":$port: $!\n";
        print "request to ", ip2addr($ip), ":$port\n";
    }
}

#! /usr/bin/perl -w
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>.
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use strict;
use Tie::RefHash;
use Sys::Hostname;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Packet ':all';

use ServBase;

my ($debug, $dump) = (1, 1);
my $hostname = hostname();

# server configuration
my $port = 4661;
my $maxClients = 100;
my $serverinfo = makeServerInfo(unpack('L', gethostbyname($hostname)),
                                $port, 
                                'pDonkeyServer!',
                                'eDonkey server in Perl');
my $message = <<END;
-----------------------------------------
    Welcome to pDonkey Server!!!
    P2P::pDonkey Version $P2P::pDonkey::Packet::VERSION
-----------------------------------------
END


my @procTable;
$procTable[PT_HELLOSERVER]  = \&processHello;
$procTable[PT_OFFERFILES]   = \&processOfferFiles;
$procTable[PT_SEARCHFILE]   = \&processSearchFile;
$procTable[PT_GETSOURCES]   = \&processGetSources;
$procTable[PT_GETSERVERLIST]= \&processGetServerList;

my $server = new ServBase(LocalPort => $port, 
                          MaxClients => $maxClients, 
                          ProcTable => \@procTable,
                          OnClientConnect => \&OnClientConnect,
#                          OnConnect => \&OnConnect,
#                          OnDisconnect => \&OnDisconnect,
                          OnDisconnect => \&OnDisconnect,
                          Dump => $dump,
                          nUsers => 0,
                          nFiles => 0);
$server->MainLoop() || die "Can't start server: $!\n";

exit;

sub OnClientConnect {
    my ($conn) = @_;
    $server->{nUsers}++;
}

sub OnDisconnect {
    my ($conn) = @_;
    RemoveShared($conn);
    $server->{nUsers}--;
    $server->Queue(undef, PT_SERVERSTATUS, $server->{nUsers}, $server->{nFiles});
}

sub processHello {
    my ($conn, $d) = @_;
    printInfo($d) if $debug;
    $conn->{ClientPort} = $d->{Port};
#    print $d->{IP}, "\n";
#    $users{$d->{Hash}} = $d;
    $server->Queue($conn, PT_IDCHANGE, $conn->{IP});
#    $server->Queue($conn, PT_UPDATESERVER, \%serverinfo);
#    $server->Queue($conn, PT_SERVERMESSAGE, $message);
    $server->Queue(undef, PT_SERVERSTATUS,  $server->{nUsers}, $server->{nFiles});
}

sub processGetServerList {
    my ($conn) = @_;
    $server->Queue($conn, PT_SERVERLIST, []);
}

sub processOfferFiles {
    my ($conn, $d) = @_;
    AddFiles($conn, $d);
    $server->Queue(undef, PT_SERVERSTATUS, $server->{nUsers}, $server->{nFiles});
}

sub processSearchFile {
    my ($conn, $d) = @_;
    $server->Queue($conn, PT_SEARCHFILERES, SearchFiles($conn, $d));
}

sub processGetSources {
    my ($conn, $hash) = @_;
    my $sources = GetSources($conn, $hash);
    $server->Queue($conn, PT_FOUNDSOURCES, $hash, $sources);
}

my %shared;
my %sources;

sub AddFiles {
    my ($conn, $l) = @_;
    my ($meta, $hash, $store, $line);

    foreach my $info (@$l) {
        $meta = $info->{Meta};
        $hash = $info->{Hash};

        $shared{$hash} = {} unless $shared{$hash};
        $line = $shared{$hash};

        if ($store = $line->{$meta->{Name}{Value}}) {
            $store->{Availability}++;
        } else {
            $line->{$meta->{Name}{Value}} = $info;
            my $m = makeMeta(TT_AVAILABILITY, 1);
            $meta->{$m->{Name}} = $m;
            $server->{nFiles}++;
        }
        if (!$sources{$hash}) {
            $sources{$hash} = {};
            tie %{$sources{$hash}}, "Tie::RefHash";
        }
        $sources{$hash}->{$conn} = 1;
        printInfo($info) if $debug;
    }
}

sub SearchFiles {
    my ($conn, $d) = @_;
    my (@found, $hash, $files);

#    my $req = $d->{Request};

    while (($hash, $files) = each %shared) {
        foreach my $name (keys %$files) {
#            $name =~ /$req/ && !$sources{$hash}->{$conn} 
            matchSearchQuery($d, $files->{$name})# && !$sources{$hash}->{$conn} 
                && push(@found, $files->{$name}) && ($debug && printInfo($files->{$name}));
        }
    }

    return \@found;
}

sub GetSources {
    my ($conn, $hash) = @_;
    my @res = ();
    foreach my $c (keys %{$sources{$hash}}) {
        next if $c == $conn;
        $c->{Socket} != $conn->{Socket} || die "Internal error";
        push @res, $c->{IP}, $c->{ClientPort};
        print "$c->{Addr}:$c->{ClientPort}\n" if $debug;
    }
    return \@res;
}

sub RemoveShared {
    my ($conn) = @_;
    foreach my $hash (keys %sources) {
        delete $sources{$hash}->{$conn};
    }
}


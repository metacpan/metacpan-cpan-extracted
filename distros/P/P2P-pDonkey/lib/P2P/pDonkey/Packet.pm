# P2P::pDonkey::Packet.pm
#
# Copyright (c) 2003 Alexey Klimkin <klimkin at cpan.org>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Packet;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
                                   PT_TEST
    PacketTagName
    packBody unpackBody
    packUDPHeader unpackUDPHeader
    packTCPHeader unpackTCPHeader

    SZ_UDP_HEADER
    SZ_TCP_HEADER

    PT_HEADER
    PT_HELLO
    PT_HELLOSERVER
    PT_HELLOCLIENT
    PT_BADPROTOCOL
    PT_GETSERVERLIST
    PT_OFFERFILES
    PT_SEARCHFILE
    PT_DISCONNECT
    PT_GETSOURCES
    PT_SEARCHUSER
    PT_CLIENTCBREQ
    PT_MORERESULTS
    PT_SERVERLIST
    PT_SEARCHFILERES
    PT_SERVERSTATUS
    PT_SERVERCBREQ
    PT_CBFAIL
    PT_SERVERMESSAGE
    PT_IDCHANGE
    PT_SERVERINFODATA
    PT_FOUNDSOURCES
    PT_SEARCHUSERRES
    PT_SENDINGPART
    PT_REQUESTPARTS
    PT_NOSUCHFILE
    PT_ENDOFOWNLOAD
    PT_VIEWFILES
    PT_VIEWFILESANS
    PT_HELLOANSWER
    PT_NEWCLIENTID
    PT_MESSAGE
    PT_FILESTATUSREQ
    PT_FILESTATUS
    PT_HASHSETREQUEST
    PT_HASHSETANSWER
    PT_SLOTREQUEST
    PT_SLOTGIVEN
    PT_SLOTRELEASE
    PT_SLOTTAKEN
    PT_FILEREQUEST
    PT_FILEREQANSWER
    PT_UDP_SERVERSTATUSREQ
    PT_UDP_SERVERSTATUS
    PT_UDP_SEARCHFILE
    PT_UDP_SEARCHFILERES
    PT_UDP_GETSOURCES
    PT_UDP_FOUNDSOURCES
    PT_UDP_CBREQUEST
    PT_UDP_CBFAIL
    PT_UDP_NEWSERVER
    PT_UDP_SERVERLIST
    PT_UDP_SERVERINFO
    PT_UDP_GETSERVERINFO
    PT_UDP_GETSERVERLIST

    PT_ADM_LOGIN
    PT_ADM_STOP
    PT_ADM_COMMAND
    PT_ADM_SERVER_LIST
    PT_ADM_FRIEND_LIST
    PT_ADM_SHARED_DIRS
    PT_ADM_SHARED_FILES
    PT_ADM_GAP_DETAILS
    PT_ADM_CORE_STATUS
    PT_ADM_MESSAGE
    PT_ADM_ERROR_MESSAGE
    PT_ADM_CONNECTED
    PT_ADM_DISCONNECTED
    PT_ADM_SERVER_STATUS
    PT_ADM_EXTENDING_SEARCH
    PT_ADM_FILE_INFO
    PT_ADM_SEARCH_FILE_RES
    PT_ADM_NEW_DOWNLOAD
    PT_ADM_REMOVE_DOWNLOAD
    PT_ADM_NEW_UPLOAD
    PT_ADM_REMOVE_UPLOAD
    PT_ADM_NEW_UPLOAD_SLOT
    PT_ADM_REMOVE_UPLOAD_SLOT
    PT_ADM_FRIEND_FILES
    PT_ADM_HASHING
    PT_ADM_FRIEND_LIST_UPDATE
    PT_ADM_DOWNLOAD_STATUS
    PT_ADM_UPLOAD_STATUS
    PT_ADM_OPTIONS
    PT_ADM_CONNECT
    PT_ADM_DISCONNECT
    PT_ADM_SEARCH_FILE
    PT_ADM_EXTEND_SEARCH_FILE
    PT_ADM_MORE_RESULTS
    PT_ADM_SEARCH_USER
    PT_ADM_EXTEND_SEARCH_USER
    PT_ADM_DOWNLOAD
    PT_ADM_PAUSE_DOWNLOAD
    PT_ADM_RESUME_DOWNLOAD
    PT_ADM_CANCEL_DOWNLOAD
    PT_ADM_SET_FILE_PRI
    PT_ADM_VIEW_FRIEND_FILES
    PT_ADM_GET_SERVER_LIST
    PT_ADM_GET_CLIENT_LIST
    PT_ADM_GET_SHARED_DIRS
    PT_ADM_SET_SHARED_DIRS
    PT_ADM_START_DL_STATUS
    PT_ADM_STOP_DL_STATUS
    PT_ADM_START_UL_STATUS
    PT_ADM_STOP_UL_STATUS
    PT_ADM_DELETE_SERVER
    PT_ADM_ADD_SERVER
    PT_ADM_SET_SERVER_PRI
    PT_ADM_GET_SHARED_FILES
    PT_ADM_GET_OPTIONS
    PT_ADM_DOWNLOAD_FILE
    PT_ADM_GET_GAP_DETAILS
    PT_ADM_GET_CORE_STATUS
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);


# Preloaded methods go here.

use Carp;
use POSIX 'ceil';
use P2P::pDonkey::Meta ':all';

use constant PT_TEST => 0x3f;

# --- packet headers
use constant SZ_UDP_HEADER          => 1;       # 1 (header marker)
use constant SZ_TCP_HEADER          => 5;       # 1 (header marker) + 4 (packet length)
# --- packet types
use constant PT_HEADER              => 0xe3;
use constant PT_HELLO               => 0x01;    # 2 hello packets!!!
use constant PT_HELLOSERVER         => 1.1;     # uses PT_HELLO
use constant PT_HELLOCLIENT         => 1.2;     # uses PT_HELLO
use constant PT_HELLOCLIENT_TAG     => 0x10;
# unused by server                     0x02 - 0x04
use constant PT_BADPROTOCOL         => 0x05;
# client <-> server
use constant PT_GETSERVERLIST       => 0x14;
use constant PT_OFFERFILES          => 0x15;
use constant PT_SEARCHFILE          => 0x16;
# unused by server                     0x17
use constant PT_DISCONNECT          => 0x18;
use constant PT_GETSOURCES          => 0x19;
use constant PT_SEARCHUSER          => 0x1a;
# ?                                    0x1b
use constant PT_CLIENTCBREQ         => 0x1c;
# Exception in Connection::doTask 25   0x20 for 16.39
use constant PT_MORERESULTS         => 0x21;
# unused by server                     0x22 - 0x31
use constant PT_SERVERLIST          => 0x32;
use constant PT_SEARCHFILERES       => 0x33;
use constant PT_SERVERSTATUS        => 0x34;
use constant PT_SERVERCBREQ         => 0x35;
use constant PT_CBFAIL              => 0x36;
# unused by server                     0x37
use constant PT_SERVERMESSAGE       => 0x38;
# unused by server                     0x39 - 0x3f
use constant PT_IDCHANGE            => 0x40;
use constant PT_SERVERINFODATA      => 0x41;
use constant PT_FOUNDSOURCES        => 0x42;
use constant PT_SEARCHUSERRES       => 0x43;
# unused by server                     0x44 - 0x45
# client <-> client
use constant PT_SENDINGPART         => 0x46;
use constant PT_REQUESTPARTS        => 0x47;
use constant PT_NOSUCHFILE          => 0x48;
use constant PT_ENDOFOWNLOAD        => 0x49;
use constant PT_VIEWFILES           => 0x4a;
use constant PT_VIEWFILESANS        => 0x4b;
use constant PT_HELLOANSWER         => 0x4c;
use constant PT_NEWCLIENTID         => 0x4d;
use constant PT_MESSAGE             => 0x4e;
use constant PT_FILESTATUSREQ       => 0x4f;
use constant PT_FILESTATUS          => 0x50;
use constant PT_HASHSETREQUEST      => 0x51;
use constant PT_HASHSETANSWER       => 0x52;
# ?                                    0x53
use constant PT_SLOTREQUEST         => 0x54;
use constant PT_SLOTGIVEN           => 0x55;
use constant PT_SLOTRELEASE         => 0x56;
use constant PT_SLOTTAKEN           => 0x57;
use constant PT_FILEREQUEST         => 0x58;
use constant PT_FILEREQANSWER       => 0x59;
# client <-> UDP server
use constant PT_UDP_SERVERSTATUSREQ => 0x96;
use constant PT_UDP_SERVERSTATUS    => 0x97;
use constant PT_UDP_SEARCHFILE      => 0x98;
use constant PT_UDP_SEARCHFILERES   => 0x99;
use constant PT_UDP_GETSOURCES      => 0x9a;
use constant PT_UDP_FOUNDSOURCES    => 0x9b;
use constant PT_UDP_CBREQUEST       => 0x9c;
# unused by server                     0x9d
use constant PT_UDP_CBFAIL          => 0x9e;
# unused by server                     0x9f
use constant PT_UDP_NEWSERVER       => 0xa0;
use constant PT_UDP_SERVERLIST      => 0xa1;
use constant PT_UDP_GETSERVERINFO   => 0xa2;
use constant PT_UDP_SERVERINFO      => 0xa3;
use constant PT_UDP_GETSERVERLIST   => 0xa4;
# CORE <-> GUI
use constant PT_ADM_LOGIN              => 0x64;
use constant PT_ADM_STOP               => 0x65;
use constant PT_ADM_COMMAND            => 0x66;
use constant PT_ADM_SERVER_LIST        => 0xaa;
use constant PT_ADM_FRIEND_LIST        => 0xab;
use constant PT_ADM_SHARED_DIRS        => 0xac;
use constant PT_ADM_SHARED_FILES       => 0xad;
use constant PT_ADM_GAP_DETAILS        => 0xae;
use constant PT_ADM_CORE_STATUS        => 0xaf;
use constant PT_ADM_MESSAGE            => 0xb4;
use constant PT_ADM_ERROR_MESSAGE      => 0xb5;
use constant PT_ADM_CONNECTED          => 0xb6;
use constant PT_ADM_DISCONNECTED       => 0xb7;
use constant PT_ADM_SERVER_STATUS      => 0xb8;
use constant PT_ADM_EXTENDING_SEARCH   => 0xb9;
use constant PT_ADM_FILE_INFO          => 0xba;
use constant PT_ADM_SEARCH_FILE_RES    => 0xbb;
use constant PT_ADM_NEW_DOWNLOAD       => 0xbc;
use constant PT_ADM_REMOVE_DOWNLOAD    => 0xbd;
use constant PT_ADM_NEW_UPLOAD         => 0xbe;
use constant PT_ADM_REMOVE_UPLOAD      => 0xbf;
use constant PT_ADM_NEW_UPLOAD_SLOT    => 0xc0;
use constant PT_ADM_REMOVE_UPLOAD_SLOT => 0xc1;
use constant PT_ADM_FRIEND_FILES       => 0xc2;
use constant PT_ADM_HASHING            => 0xc3;
use constant PT_ADM_FRIEND_LIST_UPDATE => 0xc4;
use constant PT_ADM_DOWNLOAD_STATUS    => 0xc5;
use constant PT_ADM_UPLOAD_STATUS      => 0xc6;
use constant PT_ADM_OPTIONS            => 0xc7;
use constant PT_ADM_CONNECT            => 0xc8;
use constant PT_ADM_DISCONNECT         => 0xc9;
use constant PT_ADM_SEARCH_FILE        => 0xca;
use constant PT_ADM_EXTEND_SEARCH_FILE => 0xcb;
use constant PT_ADM_MORE_RESULTS       => 0xcc;
use constant PT_ADM_SEARCH_USER        => 0xcd;
use constant PT_ADM_EXTEND_SEARCH_USER => 0xce;
use constant PT_ADM_DOWNLOAD           => 0xcf;
use constant PT_ADM_PAUSE_DOWNLOAD     => 0xd0;
use constant PT_ADM_RESUME_DOWNLOAD    => 0xd1;
use constant PT_ADM_CANCEL_DOWNLOAD    => 0xd2;
use constant PT_ADM_SET_FILE_PRI       => 0xd3;
use constant PT_ADM_VIEW_FRIEND_FILES  => 0xd4;
use constant PT_ADM_GET_SERVER_LIST    => 0xd5;
use constant PT_ADM_GET_CLIENT_LIST    => 0xd6;
use constant PT_ADM_GET_SHARED_DIRS    => 0xd7;
use constant PT_ADM_SET_SHARED_DIRS    => 0xd8;
use constant PT_ADM_START_DL_STATUS    => 0xd9;
use constant PT_ADM_STOP_DL_STATUS     => 0xda;
use constant PT_ADM_START_UL_STATUS    => 0xdb;
use constant PT_ADM_STOP_UL_STATUS     => 0xdc;
use constant PT_ADM_DELETE_SERVER      => 0xdd;
use constant PT_ADM_ADD_SERVER         => 0xde;
use constant PT_ADM_SET_SERVER_PRI     => 0xdf;
use constant PT_ADM_GET_SHARED_FILES   => 0xe0;
use constant PT_ADM_GET_OPTIONS        => 0xe1;
use constant PT_ADM_DOWNLOAD_FILE      => 0xe2;
use constant PT_ADM_GET_GAP_DETAILS    => 0xe3;
use constant PT_ADM_GET_CORE_STATUS    => 0xe4;

my (@PacketTagName, @packTable, @unpackTable);

sub PacketTagName {
    my $name = $PacketTagName[$_[0]];
    return $name ? $name : sprintf("Unknown(0x%x)", $_[0]);
}

# empty body
my $packEmpty = sub {
    return '';
};
my $unpackEmpty = sub {
    return 1;
};

sub unpackBody {
    my ($pt) = shift;
    defined($$pt = &unpackB) or return;
    my $f;
    if ($$pt == PT_HELLO) {
        my $off = $_[1];
        my $d;
        $f = $unpackTable[PT_HELLOCLIENT];
        if (defined($d = &$f)) {
            $$pt = PT_HELLOCLIENT;
            return $d;
        } else {
            $_[1] = $off;
            $$pt = PT_HELLOSERVER;
            $f = $unpackTable[PT_HELLOSERVER];
            return &$f;
        }
    } else {
        $f = $unpackTable[$$pt];
        defined($f) 
            or carp("Don't know how to unpack " . sprintf("0x%x",$$pt) . " packets\n")
            && return;
        return &$f;
    }
}
sub packBody {
    my $pt = shift;
    my $f;
    defined($f = $packTable[$pt]) or return;
#    $f or confess "Don't know how to pack ".sprintf("0x%x",$pt)." packets\n";
#    return pack('Ca*', $pt, &$f);
    return $f ? pack('Ca*', $pt, &$f) : pack('C', $pt);
}

sub unpackUDPHeader {
    my $pth;
    defined ($pth = &unpackB) and $pth == PT_HEADER or return;
    return 1;
}
sub packUDPHeader {
    return pack('C', PT_HEADER);
}

sub unpackTCPHeader {
    my ($len, $pth);
    defined($pth = &unpackB) and $pth == PT_HEADER or return;
    defined($len = &unpackD) or return;
    return $len;
}
sub packTCPHeader {
    return pack('CL', PT_HEADER, @_);
}

# -------------------------------------------------------------------
$PacketTagName[PT_TEST] = 'test';
$unpackTable[PT_TEST] = $unpackEmpty;
$packTable[PT_TEST] = $packEmpty;
# -------------------------------------------------------------------
# -------------------------------------------------------------------
$PacketTagName[PT_HEADER]           = 'Header';
# -------------------------------------------------------------------
$PacketTagName[PT_HELLO]            = 'Hello';
$unpackTable[PT_HELLO]              = sub {
    croak('You must specify PT_HELLOSERVER or PT_HELLOCLIENT instead of PT_HELLO.');
};
$packTable[PT_HELLO]                = sub {
    croak('You must specify PT_HELLOSERVER or PT_HELLOCLIENT instead of PT_HELLO.');
};
# -------------------------------------------------------------------
$PacketTagName[PT_HELLOCLIENT]      = 'Hello client';
$unpackTable[PT_HELLOCLIENT]        = sub {
    my ($d, $subtag);
    defined($subtag = &unpackB)
        and $subtag == PT_HELLOCLIENT_TAG
        and defined($d = &unpackInfo)
        and ($d->{ServerIP}, $d->{ServerPort}) = &unpackAddr
        or return;
    return $d;
};
$packTable[PT_HELLOCLIENT]          = sub {
    my ($d) = @_;
    return packB(PT_HELLOCLIENT_TAG) . &packInfo 
        . packAddr($d->{ServerIP}, $d->{ServerPort});
};
# -------------------------------------------------------------------
$PacketTagName[PT_HELLOSERVER]      = 'Hello server';
$unpackTable[PT_HELLOSERVER]        = \&unpackInfo;
$packTable[PT_HELLOSERVER]          = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_BADPROTOCOL]      = 'Bad protocol';
$unpackTable[PT_BADPROTOCOL]        = $unpackEmpty;
$packTable[PT_BADPROTOCOL]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_GETSERVERLIST]    = 'Get server list';
$unpackTable[PT_GETSERVERLIST]      = $unpackEmpty;
$packTable[PT_GETSERVERLIST]        = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_OFFERFILES]       = 'Offer files';
$unpackTable[PT_OFFERFILES]         = \&unpackInfoList;
$packTable[PT_OFFERFILES]           = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHFILE]       = 'Search file';
$unpackTable[PT_SEARCHFILE]         = \&unpackSearchQuery;
$packTable[PT_SEARCHFILE]           = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_DISCONNECT]       = 'Disconnect';
$unpackTable[PT_DISCONNECT]         = $unpackEmpty;
$packTable[PT_DISCONNECT]           = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_GETSOURCES]       = 'Get sources';
$unpackTable[PT_GETSOURCES]         = \&unpackHash;
$packTable[PT_GETSOURCES]           = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHUSER]       = 'Search user';
$unpackTable[PT_SEARCHUSER]         = \&unpackSearchQuery;
$packTable[PT_SEARCHUSER]           = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_CLIENTCBREQ]      = 'Client callback request';
$unpackTable[PT_CLIENTCBREQ]        = \&unpackD;
$packTable[PT_CLIENTCBREQ]          = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_MORERESULTS]      = 'More results';
$unpackTable[PT_MORERESULTS]        = $unpackEmpty;
$packTable[PT_MORERESULTS]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERLIST]       = 'Server list';
$unpackTable[PT_SERVERLIST]         = \&unpackAddrList;
$packTable[PT_SERVERLIST]           = \&packAddrList;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHFILERES]    = 'Search file results';
$unpackTable[PT_SEARCHFILERES]      = sub {
    my ($res, $more);
    $res = &unpackInfoList or return;
    defined($more = &unpackB) or return;
    return ($res, $more);
};
$packTable[PT_SEARCHFILERES]        = sub {
    my ($res, $more) = @_;
    return packInfoList($res) . packB($more);
};
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERSTATUS]     = 'Server status';
$unpackTable[PT_SERVERSTATUS]       = sub {
    my ($users, $files);
    defined($users = &unpackD) or return;
    defined($files = &unpackD) or return;
#    return {Users => $users, Files => $files};
    return ($users, $files);
};
$packTable[PT_SERVERSTATUS]         = sub {
#    my ($d) = @_;
#    return pack('LL', $d->{Users}, $d->{Files});
    return pack('LL', @_);
};
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERCBREQ]      = 'Server callback request';
$unpackTable[PT_SERVERCBREQ]        = \&unpackAddr;
$packTable[PT_SERVERCBREQ]          = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_CBFAIL]           = 'Callback fail';
$unpackTable[PT_CBFAIL]             = \&unpackD;
$packTable[PT_CBFAIL]               = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERMESSAGE]    = 'Server message';
$unpackTable[PT_SERVERMESSAGE]      = \&unpackS;
$packTable[PT_SERVERMESSAGE]        = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_IDCHANGE]         = 'ID change';
$unpackTable[PT_IDCHANGE]           = \&unpackD;
$packTable[PT_IDCHANGE]             = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_SERVERINFODATA]   = 'Server info data';
$unpackTable[PT_SERVERINFODATA]     = \&unpackInfo;
$packTable[PT_SERVERINFODATA]       = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_FOUNDSOURCES]     = 'Found sources';
my $unpackFoundSources = sub {
    my ($hash, $addrl);
    defined($hash  = &unpackHash) or return;
    $addrl = &unpackAddrList or return;
#    return {Hash => $hash, Addresses => $addrl};
    return ($hash, $addrl);
};
my $packFoundSources = sub {
#    my ($d) = @_;
#    return packHash($d->{Hash}) . packAddrList($d->{Addresses});
    my ($hash, $addrl) = @_;
    return packHash($hash) . packAddrList($addrl);
};
$unpackTable[PT_FOUNDSOURCES]       = $unpackFoundSources;
$packTable[PT_FOUNDSOURCES]         = $packFoundSources;
# -------------------------------------------------------------------
$PacketTagName[PT_SEARCHUSERRES]    = 'Search user results';
$unpackTable[PT_SEARCHUSERRES]      = \&unpackInfoList;
$packTable[PT_SEARCHUSERRES]        = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_SENDINGPART]      = 'Sending part';
$unpackTable[PT_SENDINGPART]        = sub {
    my ($hash, $start, $end, $data);
    defined($hash   = &unpackHash) or return;
    defined($start  = &unpackD) or return;
    defined($end    = &unpackD) or return;
    my $len = $end - $start;
    $len > 0 or return;
    $data = unpack("x$_[1] a$len", $_[0]); # copy data for postprocessing
#    return {Hash => $hash, Start => $start, End => $end, Data => \$data};
    $_[1] += $len;
    return ($hash, $start, $end, \$data);
};
$packTable[PT_SENDINGPART]          = sub {
#    my ($d) = @_;
#    return packHash($d->{Hash}) 
#        . pack('LL a*', $d->{Start}, $d->{End}, $$d->{Data});
    my ($hash, $start, $end, $data) = @_;
    return packHash($hash) . pack('LL a*', $start, $end, $$data)
};
# -------------------------------------------------------------------
$PacketTagName[PT_REQUESTPARTS]     = 'Request parts';
$unpackTable[PT_REQUESTPARTS]       = sub {
    my ($hash, $o, @start, @end);
    defined($hash   = &unpackHash) or return;
    defined($o      = &unpackD) and push(@start, $o) or return;
    defined($o      = &unpackD) and push(@start, $o) or return;
    defined($o      = &unpackD) and push(@start, $o) or return;
    defined($o      = &unpackD) and push(@end, $o) or return;
    defined($o      = &unpackD) and push(@end, $o) or return;
    defined($o      = &unpackD) and push(@end, $o) or return;
#    return {Hash => $hash, Gaps => [sort {$a <=> $b} (@start, @end)]};
    return ($hash, sort {$a <=> $b} (@start, @end));
};
$packTable[PT_REQUESTPARTS]         = sub {
    my $hash = shift;
#    my ($d) = @_;
    my ($gaps, @start, @end);
#    $gaps = $d->{Gaps};
    foreach my $i (0, 2, 4) {
#        push @start, $gaps->[$i];
#        push @end,   $gaps->[$i+1];
        push @start, ($_[$i] or 0);
        push @end,   ($_[$i+1] or 0);
    }
    return packHash($hash) . pack('LLLLLL', @start, @end);
#    return packHash($d->{Hash}) . pack('LLLLLL', @start, @end);
};
# -------------------------------------------------------------------
$PacketTagName[PT_NOSUCHFILE]       = 'No such file';
$unpackTable[PT_NOSUCHFILE]         = \&unpackHash;
$packTable[PT_NOSUCHFILE]           = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ENDOFOWNLOAD]     = 'End of download';
$unpackTable[PT_ENDOFOWNLOAD]       = \&unpackHash;
$packTable[PT_ENDOFOWNLOAD]         = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_VIEWFILES]        = 'View files';
$unpackTable[PT_VIEWFILES]          = $unpackEmpty;
$packTable[PT_VIEWFILES]            = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_VIEWFILESANS]     = 'View files answer';
$unpackTable[PT_VIEWFILESANS]       = \&unpackInfoList;
$packTable[PT_VIEWFILESANS]         = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_HELLOANSWER]      = 'Hello answer';
$unpackTable[PT_HELLOANSWER]        = sub {
    my ($uinfo, $sip, $sport);
    $uinfo  = &unpackInfo or return;
    ($uinfo->{ServerIP}, $uinfo->{ServerPort}) = &unpackAddr or return;
    return $uinfo;
};
$packTable[PT_HELLOANSWER]          = sub {
    my ($d) = @_;
    return packInfo($d) . packAddr($d->{ServerIP}, $d->{ServerPort});
};
# -------------------------------------------------------------------
$PacketTagName[PT_NEWCLIENTID]      = 'New client ID';
$unpackTable[PT_NEWCLIENTID]        = sub {
    my ($id, $newid);
    defined($id    = &unpackD) or return;
    defined($newid = &unpackD) or return;
#    return {Users => $users, Files => $files};
    return ($id, $newid);
};
$packTable[PT_NEWCLIENTID]          = sub {
#    my ($d) = @_;
#    return pack('LL', $d->{Users}, $d->{Files});
    return pack('LL', @_);
};
# -------------------------------------------------------------------
$PacketTagName[PT_MESSAGE]          = 'Message';
$unpackTable[PT_MESSAGE]            = \&unpackS;
$packTable[PT_MESSAGE]              = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_FILESTATUSREQ]    = 'File status request';
$unpackTable[PT_FILESTATUSREQ]      = \&unpackHash;
$packTable[PT_FILESTATUSREQ]        = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_FILESTATUS]       = 'File status';
$unpackTable[PT_FILESTATUS]         = sub {
    my ($hash, $nparts, @status);
    defined($hash   = &unpackHash) or return;
    defined($nparts = &unpackW) or return;
    if ($nparts) {
        my $len;
        $_ = unpack("x$_[1] b$nparts", $_[0]);
        defined && (($len = length) == $nparts) or return;
        $_[1] += ceil $nparts/8;
        while ($len--) { unshift @status, chop }
    } else {
        # handle 00 00 00 
        &unpackB;
    }
#    return {Hash => $hash, Status => $status};
    return ($hash, \@status);
};
$packTable[PT_FILESTATUS]           = sub {
#   my ($d) = @_;
#   return packHash($d->{Hash}) 
#       . pack('S b*', length $d->{Status}, $d->{Status});
    my ($hash, $status) = @_;
    my $st = join '', @$status;
    return packHash($hash) . pack('S b*', length $st, $st);
};
# -------------------------------------------------------------------
$PacketTagName[PT_HASHSETREQUEST]   = 'Hashset request';
$unpackTable[PT_HASHSETREQUEST]     = \&unpackHash;
$packTable[PT_HASHSETREQUEST]       = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_HASHSETANSWER]    = 'Hashset answer';
$unpackTable[PT_HASHSETANSWER]      = sub {
    my ($hash, $nparts, @parthashes, $ph);
    defined($hash   = &unpackHash) or return;
    defined($nparts = &unpackW) or return;
    @parthashes = ();
    while ($nparts--) {
        defined($ph = &unpackHash) or return;
        push @parthashes, $ph;
    }
#    return {Hash => $hash, Parthashes => \@parthashes};
    return ($hash, \@parthashes);
};
$packTable[PT_HASHSETANSWER]        = sub {
    my ($hash, $parthashes) = @_;
#    my ($d) = @_;
#    my $parthashes = $d->{Parthashes};
#    my $res = packHash($d->{Hash}) . packW(scalar @$parthashes);
    my $res = packHash($hash) . packW(scalar @$parthashes);
    foreach my $ph (@$parthashes) {
        $res .= packHash($ph);
    }
    return $res;
};
# -------------------------------------------------------------------
$PacketTagName[PT_SLOTREQUEST]      = 'Slot request';
$unpackTable[PT_SLOTREQUEST]        = $unpackEmpty;
$packTable[PT_SLOTREQUEST]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_SLOTGIVEN]        = 'Slot given';
$unpackTable[PT_SLOTGIVEN]          = $unpackEmpty;
$packTable[PT_SLOTGIVEN]            = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_SLOTRELEASE]      = 'Slot release';
$unpackTable[PT_SLOTRELEASE]        = $unpackEmpty;
$packTable[PT_SLOTRELEASE]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_SLOTTAKEN]        = 'Slot taken';
$unpackTable[PT_SLOTTAKEN]          = $unpackEmpty;
$packTable[PT_SLOTTAKEN]            = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_FILEREQUEST]      = 'File request';
$unpackTable[PT_FILEREQUEST]        = \&unpackHash;
$packTable[PT_FILEREQUEST]          = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_FILEREQANSWER]    = 'File request answer';
$unpackTable[PT_FILEREQANSWER]      = sub {
    my ($hash, $fname);
    defined($hash  = &unpackHash) or return;
    defined($fname = &unpackS) or return;
#    return {Hash => $hash, Name => $fname};
    return ($hash, $fname);
};
$packTable[PT_FILEREQANSWER]        = sub {
    my ($hash, $fname) = @_;
    return packHash($hash) . packS($fname);
#    my ($d) = @_;
#    return packHash($d->{Hash}) . packS($d->{Name});
};
# -------------------------------------------------------------------
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERSTATUSREQ]  = 'UDP Server status request';
$unpackTable[PT_UDP_SERVERSTATUSREQ]    = \&unpackD;
$packTable[PT_UDP_SERVERSTATUSREQ]      = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERSTATUS]     = 'UDP Server status';
$unpackTable[PT_UDP_SERVERSTATUS]       = sub {
    my ($ip, $nusers, $nfiles);
    defined($ip = &unpackD) or return;
    defined($nusers = &unpackD) or return;
    defined($nfiles = &unpackD) or return;
    return ($ip, $nusers, $nfiles);
};
$packTable[PT_UDP_SERVERSTATUS]         = sub {
    return pack('LLL', @_);
};
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SEARCHFILE]       = 'UDP Search file';
$unpackTable[PT_UDP_SEARCHFILE]         = \&unpackSearchQuery;
$packTable[PT_UDP_SEARCHFILE]           = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SEARCHFILERES]    = 'UDP Search file result';
$unpackTable[PT_UDP_SEARCHFILERES]      = \&unpackInfo;
$packTable[PT_UDP_SEARCHFILERES]        = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_GETSOURCES]       = 'UDP Get sources';
$unpackTable[PT_UDP_GETSOURCES]         = \&unpackHash;
$packTable[PT_UDP_GETSOURCES]           = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_FOUNDSOURCES]     = 'UDP Found Sources';
$unpackTable[PT_UDP_FOUNDSOURCES]       = $unpackFoundSources;
$packTable[PT_UDP_FOUNDSOURCES]         = $packFoundSources;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_CBREQUEST]        = 'UDP Callback request';
$unpackTable[PT_UDP_CBREQUEST]          = sub {
    my ($ip, $port, $cid);
    ($ip, $port) = &unpackAddr or return;
    defined($cid = &unpackD) or return;
    return ($ip, $port, $cid);
};
$packTable[PT_UDP_CBREQUEST]            = sub {
    my ($ip, $port, $cid) = @_;
    return packAddr($ip, $port) . packD($cid);
};
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_CBFAIL]           = 'UDP Callback fail';
$unpackTable[PT_UDP_CBFAIL]             = \&unpackD;
$packTable[PT_UDP_CBFAIL]               = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_NEWSERVER]        = 'UDP New server';
$unpackTable[PT_UDP_NEWSERVER]          = \&unpackAddr;
$packTable[PT_UDP_NEWSERVER]            = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERLIST]       = 'UDP Server list';
$unpackTable[PT_UDP_SERVERLIST]         = \&unpackAddrList;
$packTable[PT_UDP_SERVERLIST]           = \&packAddrList;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_GETSERVERINFO]    = 'UDP Get server info';
$unpackTable[PT_UDP_GETSERVERINFO]      = $unpackEmpty;
$packTable[PT_UDP_GETSERVERINFO]        = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_SERVERINFO]       = 'UDP Server info';
$unpackTable[PT_UDP_SERVERINFO]         = sub {
    my ($name, $desc);
    defined($name = &unpackS) or return;
    defined($desc = &unpackS) or return;
    return ($name, $desc);
};
$packTable[PT_UDP_SERVERINFO]           = sub {
    my ($name, $desc) = @_;
    return packS($name) . packS($desc);
};
# -------------------------------------------------------------------
$PacketTagName[PT_UDP_GETSERVERLIST]    = 'UDP Get server list';
$unpackTable[PT_UDP_GETSERVERLIST]      = $unpackEmpty;
$packTable[PT_UDP_GETSERVERLIST]        = $packEmpty;
# -------------------------------------------------------------------

# -------------------------------------------------------------------
$PacketTagName[PT_ADM_LOGIN]            = 'Adm Login';
$unpackTable[PT_ADM_LOGIN]              = sub {
    my ($user, $pass);
    defined($user = &unpackS) or return;
    defined($pass = &unpackS) or return;
    return ($user, $pass);
};
$packTable[PT_ADM_LOGIN]                = sub {
    my ($user, $pass) = @_;
    return packS($user) . packS($pass);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_STOP]             = 'Adm Stop';
$unpackTable[PT_ADM_STOP]               = $unpackEmpty;
$packTable[PT_ADM_STOP]                 = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_COMMAND]          = 'Adm Command';
$unpackTable[PT_ADM_COMMAND]            = \&unpackS;
$packTable[PT_ADM_COMMAND]              = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SERVER_LIST]      = 'Adm Server list';
$unpackTable[PT_ADM_SERVER_LIST]        = \&unpackInfoList;
$packTable[PT_ADM_SERVER_LIST]          = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_FRIEND_LIST]      = 'Adm Friend list';
$unpackTable[PT_ADM_FRIEND_LIST]        = \&unpackInfoList;
$packTable[PT_ADM_FRIEND_LIST]          = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SHARED_DIRS]      = 'Adm Shared dirs';
$unpackTable[PT_ADM_SHARED_DIRS]        = \&unpackSList;
$packTable[PT_ADM_SHARED_DIRS]          = \&packSList;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SHARED_FILES]     = 'Adm Shared files';
$unpackTable[PT_ADM_SHARED_FILES]       = \&unpackInfoList;
$packTable[PT_ADM_SHARED_FILES]         = \&packInfoList;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GAP_DETAILS]      = 'Adm Gap details';
$unpackTable[PT_ADM_GAP_DETAILS]        = sub {
    my ($hash, $l);
    defined($hash = &unpackHash) or return;
    $l = &unpackGapInfoList or return;
    return ($hash, $l);
};
$packTable[PT_ADM_GAP_DETAILS]          = sub {
    my ($hash, $l) = @_;
    return packHash($hash) . packGapInfoList($l);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_CORE_STATUS]      = 'Adm Core status';
$unpackTable[PT_ADM_CORE_STATUS]        = sub {
    my ($temp, $incoming, $needed, $cid, $nconn, $nqueue);
    defined($temp     = &unpackF) or return;
    defined($incoming = &unpackF) or return;
    defined($needed   = &unpackF) or return;
    defined($cid      = &unpackD) or return;
    defined($nconn    = &unpackW) or return;
    defined($nqueue   = &unpackW) or return;
    return ($temp, $incoming, $needed, $cid, $nconn, $nqueue);
};
$packTable[PT_ADM_CORE_STATUS]          = sub {
    my ($temp, $incoming, $needed, $cid, $nconn, $nqueue) = @_;
    return packF($temp) . packF($incoming) . packF($needed) 
         . packD($cid) . packW($nconn) . packW($nqueue);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_MESSAGE]          = 'Adm Message';
$unpackTable[PT_ADM_MESSAGE]            = \&unpackS;
$packTable[PT_ADM_MESSAGE]              = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_ERROR_MESSAGE]    = 'Adm Error message';
$unpackTable[PT_ADM_ERROR_MESSAGE]      = \&unpackS;
$packTable[PT_ADM_ERROR_MESSAGE]        = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_CONNECTED]        = 'Adm Connected';
$unpackTable[PT_ADM_CONNECTED]          = \&unpackS;
$packTable[PT_ADM_CONNECTED]            = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_DISCONNECTED]     = 'Adm ';
$unpackTable[PT_ADM_DISCONNECTED]       = $unpackEmpty;
$packTable[PT_ADM_DISCONNECTED]         = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SERVER_STATUS]    = 'Adm Server status';
$unpackTable[PT_ADM_SERVER_STATUS]      = $unpackTable[PT_SERVERSTATUS];
$packTable[PT_ADM_SERVER_STATUS]        = $packTable[PT_SERVERSTATUS];
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_EXTENDING_SEARCH] = 'Adm Extending search';
$unpackTable[PT_ADM_EXTENDING_SEARCH]   = \&unpackS;
$packTable[PT_ADM_EXTENDING_SEARCH]     = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_FILE_INFO]        = 'Adm File info';
$unpackTable[PT_ADM_FILE_INFO]          = \&unpackInfo;
$packTable[PT_ADM_FILE_INFO]            = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SEARCH_FILE_RES]  = 'Adm Search file results';
$unpackTable[PT_ADM_SEARCH_FILE_RES]    = $unpackTable[PT_SEARCHFILERES];
$packTable[PT_ADM_SEARCH_FILE_RES]      = $packTable[PT_SEARCHFILERES];
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_NEW_DOWNLOAD]     = 'Adm New download';
$unpackTable[PT_ADM_NEW_DOWNLOAD]       = sub {
    my ($info, $pri, $fname);
    $info = &unpackInfo or return;
    defined($pri = &unpackB) or return;
    defined($fname = &unpackS) or return;
    return ($info, $pri, $fname);
};
$packTable[PT_ADM_NEW_DOWNLOAD]         = sub {
    my ($info, $pri, $fname) = @_;
    return packInfo($info) . packB($pri) . packS($fname);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_REMOVE_DOWNLOAD]  = 'Adm Remove download';
$unpackTable[PT_ADM_REMOVE_DOWNLOAD]    = \&unpackHash;
$packTable[PT_ADM_REMOVE_DOWNLOAD]      = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_NEW_UPLOAD]       = 'Adm New upload';
$unpackTable[PT_ADM_NEW_UPLOAD]         = sub {
    my ($fname, $cinfo);
    defined($fname = &unpackS) or return;
    $cinfo = &unpackInfo or return;
    return ($fname, $cinfo);
};
$packTable[PT_ADM_NEW_UPLOAD]           = sub {
    my ($fname, $cinfo) = @_;
    return packS($fname) . packInfo($cinfo);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_REMOVE_UPLOAD]    = 'Adm Remove upload';
$unpackTable[PT_ADM_REMOVE_UPLOAD]      = \&unpackHash;
$packTable[PT_ADM_REMOVE_UPLOAD]        = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_NEW_UPLOAD_SLOT]  = 'Adm New upload slot';
$unpackTable[PT_ADM_NEW_UPLOAD_SLOT]    = sub {
    my ($slot, $peername);
    defined($slot     = &unpackD) or return;
    defined($peername = &unpackS) or return;
    return ($slot, $peername);
};
$packTable[PT_ADM_NEW_UPLOAD_SLOT]      = sub {
    my ($slot, $peername) = @_;
    return packD($slot) . packS($peername);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_REMOVE_UPLOAD_SLOT] = 'Adm Remove upload slot';
$unpackTable[PT_ADM_REMOVE_UPLOAD_SLOT] = \&unpackD;
$packTable[PT_ADM_REMOVE_UPLOAD_SLOT]   = \&packD;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_FRIEND_FILES]     = 'Adm Friend files';
#$unpackTable[PT_ADM_FRIEND_FILES]       = $unpackEmpty;
#$packTable[PT_ADM_FRIEND_FILES]         = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_HASHING]          = 'Adm Hashing';
$unpackTable[PT_ADM_HASHING]            = \&unpackS;
$packTable[PT_ADM_HASHING]              = \&packS;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_FRIEND_LIST_UPDATE] = 'Adm Friend list update';
#$unpackTable[PT_ADM_FRIEND_LIST_UPDATE] = $unpackEmpty;
#$packTable[PT_ADM_FRIEND_LIST_UPDATE]   = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_DOWNLOAD_STATUS]  = 'Adm Download status';
$unpackTable[PT_ADM_DOWNLOAD_STATUS]    = sub {
    my ($len, $slot, $stat, $speed, $trans, $avail, $srcs, @res);
    @res = ();
    defined($len = &unpackW) or return;
    while ($len--) {
        defined($slot  = &unpackW) or return;
        defined($stat  = &unpackB) or return;
        defined($speed = &unpackF) or return;
        defined($trans = &unpackD) or return;
        defined($avail = &unpackB) or return;
        defined($srcs  = &unpackB) or return;
        push @res, {Slot => $slot, Status => $stat, Speed => $speed,
                    Transferred => $trans, Availability => $avail,
                    Sources => $srcs};
    }
    return \@res;
};
$packTable[PT_ADM_DOWNLOAD_STATUS]      = sub {
    my ($l) = @_;
    my $res = packW(scalar @$l);
    foreach my $i (@$l) {
        $res .= packW($i->{Slot})
             .  packB($i->{Status})
             .  packF($i->{Speed})
             .  packD($i->{Transferred})
             .  packB($i->{Availability})
             .  packB($i->{Sources});
    }
    return $res;
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_UPLOAD_STATUS]    = 'Adm Upload status';
$unpackTable[PT_ADM_UPLOAD_STATUS]      = sub {
    my ($len, $slot, $speed, @res);
    @res = ();
    defined($len = &unpackW) or return;
    while ($len--) {
        defined($slot  = &unpackW) or return;
        defined($speed = &unpackF) or return;
        push @res, {Slot => $slot, Speed => $speed};
    }
    return \@res;
};
$packTable[PT_ADM_UPLOAD_STATUS]        = sub {
    my ($l) = @_;
    my $res = packW(scalar @$l);
    foreach my $i (@$l) {
        $res .= packW($i->{Slot})
             .  packF($i->{Speed});
    }
    return $res;
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_OPTIONS]          = 'Adm Options';
$unpackTable[PT_ADM_OPTIONS]            = sub {
    my ($ver, $maxDL, $maxUL, $port, $maxCon, $nick,
        $temp, $incoming, $auto, $rdead, $privmsg, $savecor,
        $verif, $admport, $cbd, $lines, $pid, $maxNUp);
    defined($ver    = &unpackW) or return;
    defined($maxDL  = &unpackF) or return;
    defined($maxUL  = &unpackF) or return;
    defined($port   = &unpackW) or return;
    defined($maxNUp = &unpackW) or return;
    defined($nick   = &unpackS) or return;
    defined($temp   = &unpackS) or return;
    defined($incoming = &unpackS) or return;
    defined($auto   = &unpackB) or return;
    defined($rdead  = &unpackB) or return;
    defined($privmsg= &unpackB) or return;
    defined($savecor= &unpackB) or return;
    defined($verif  = &unpackB) or return;
    defined($admport= &unpackW) or return;
    defined($maxCon = &unpackD) or return;
    defined($cbd    = &unpackD) or return;
    defined($lines  = &unpackF) or return;
    defined($pid    = &unpackD) or return;
    return {
        Version         => $ver, 
        userMaxDownF    => $maxDL,
        userMaxUpF      => $maxUL,
        incomingPort    => $port,
        maxNumUp        => $maxNUp,
        Nickname        => $nick,
        temp            => $temp,
        incoming        => $incoming,
        auto            => $auto,
        servRemove      => $rdead,
        pmAllow         => $privmsg,
        saveCor         => $savecor,
        verifyCancel    => $verif,
        adminDoorPort   => $admport,
        maxCon          => $maxCon,
        cbd             => $cbd,
        lineDown        => $lines,
        PID             => $pid
    };
};
$packTable[PT_ADM_OPTIONS]              = sub {
    my ($p) = @_;
    return
          packW($p->{Version})
        . packF($p->{userMaxDownF})
        . packF($p->{userMaxUpF})
        . packW($p->{incomingPort})
        . packW($p->{maxNumUp})
        . packS($p->{Nickname})
        . packS($p->{temp})
        . packS($p->{incoming})
        . packB($p->{auto})
        . packB($p->{servRemove})
        . packB($p->{pmAllow})
        . packB($p->{saveCor})
        . packB($p->{verifyCancel})
        . packW($p->{adminDoorPort})
        . packD($p->{maxCon})
        . packD($p->{cbd})
        . packF($p->{lineDown})
        . packD($p->{PID})
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_CONNECT]          = 'Adm Connect';
$unpackTable[PT_ADM_CONNECT]            = \&unpackAddr;
$packTable[PT_ADM_CONNECT]              = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_DISCONNECT]       = 'Adm Disconnect';
$unpackTable[PT_ADM_DISCONNECT]         = $unpackEmpty;
$packTable[PT_ADM_DISCONNECT]           = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SEARCH_FILE]      = 'Adm Search file';
$unpackTable[PT_ADM_SEARCH_FILE]        = \&unpackSearchQuery;
$packTable[PT_ADM_SEARCH_FILE]          = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_EXTEND_SEARCH_FILE] = 'Adm Extend search file';
$unpackTable[PT_ADM_EXTEND_SEARCH_FILE] = $unpackEmpty;
$packTable[PT_ADM_EXTEND_SEARCH_FILE]   = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_MORE_RESULTS]     = 'Adm More results';
$unpackTable[PT_ADM_MORE_RESULTS]       = $unpackEmpty;
$packTable[PT_ADM_MORE_RESULTS]         = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SEARCH_USER]      = 'Adm Search user';
$unpackTable[PT_ADM_SEARCH_USER]        = \&unpackSearchQuery;
$packTable[PT_ADM_SEARCH_USER]          = \&packSearchQuery;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_EXTEND_SEARCH_USER] = 'Adm Extend search user';
$unpackTable[PT_ADM_EXTEND_SEARCH_USER] = $unpackEmpty;
$packTable[PT_ADM_EXTEND_SEARCH_USER]   = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_DOWNLOAD]         = 'Adm Download';
$unpackTable[PT_ADM_DOWNLOAD]           = \&unpackHash;
$packTable[PT_ADM_DOWNLOAD]             = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_PAUSE_DOWNLOAD]   = 'Adm Pause download';
$unpackTable[PT_ADM_PAUSE_DOWNLOAD]     = \&unpackHash;
$packTable[PT_ADM_PAUSE_DOWNLOAD]       = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_RESUME_DOWNLOAD]  = 'Adm Resume download';
$unpackTable[PT_ADM_RESUME_DOWNLOAD]    = \&unpackHash;
$packTable[PT_ADM_RESUME_DOWNLOAD]      = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_CANCEL_DOWNLOAD]  = 'Adm Cancel download';
$unpackTable[PT_ADM_CANCEL_DOWNLOAD]    = \&unpackHash;
$packTable[PT_ADM_CANCEL_DOWNLOAD]      = \&packHash;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SET_FILE_PRI]     = 'Adm Set file priority';
$unpackTable[PT_ADM_SET_FILE_PRI]       = sub {
    my ($hash, $pri);
    defined($hash = &unpackHash) or return;
    defined($pri  = &unpackB) or return;
    return ($hash, $pri);
};
$packTable[PT_ADM_SET_FILE_PRI]         = sub {
    my ($hash, $pri) = @_;
    return packHash($hash) . packB($pri);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_VIEW_FRIEND_FILES] = 'Adm View friend files';
#$unpackTable[PT_ADM_VIEW_FRIEND_FILES]  = $unpackEmpty;
#$packTable[PT_ADM_VIEW_FRIEND_FILES]    = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_SERVER_LIST]  = 'Adm Get server list';
$unpackTable[PT_ADM_GET_SERVER_LIST]    = $unpackEmpty;
$packTable[PT_ADM_GET_SERVER_LIST]      = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_CLIENT_LIST]  = 'Adm Get client list';
$unpackTable[PT_ADM_GET_CLIENT_LIST]    = $unpackEmpty;
$packTable[PT_ADM_GET_CLIENT_LIST]      = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_SHARED_DIRS]  = 'Adm Get shared dirs';
$unpackTable[PT_ADM_GET_SHARED_DIRS]    = $unpackEmpty;
$packTable[PT_ADM_GET_SHARED_DIRS]      = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SET_SHARED_DIRS]  = 'Adm Set shared dirs';
#$unpackTable[PT_ADM_SET_SHARED_DIRS]    = $unpackEmpty;
#$packTable[PT_ADM_SET_SHARED_DIRS]      = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_START_DL_STATUS]  = 'Adm Start dl status';
$unpackTable[PT_ADM_START_DL_STATUS]    = $unpackEmpty;
$packTable[PT_ADM_START_DL_STATUS]      = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_STOP_DL_STATUS]   = 'Adm Stop dl status';
$unpackTable[PT_ADM_STOP_DL_STATUS]     = $unpackEmpty;
$packTable[PT_ADM_STOP_DL_STATUS]       = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_START_UL_STATUS]  = 'Adm Start ul status';
$unpackTable[PT_ADM_START_UL_STATUS]    = $unpackEmpty;
$packTable[PT_ADM_START_UL_STATUS]      = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_STOP_UL_STATUS]   = 'Adm Stop ul status';
$unpackTable[PT_ADM_STOP_UL_STATUS]     = $unpackEmpty;
$packTable[PT_ADM_STOP_UL_STATUS]       = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_DELETE_SERVER]    = 'Adm Delete server';
$unpackTable[PT_ADM_DELETE_SERVER]      = \&unpackAddr;
$packTable[PT_ADM_DELETE_SERVER]        = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_ADD_SERVER]       = 'Adm Add server';
$unpackTable[PT_ADM_ADD_SERVER]         = \&unpackAddr;
$packTable[PT_ADM_ADD_SERVER]           = \&packAddr;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_SET_SERVER_PRI]   = 'Adm Set server pri';
$unpackTable[PT_ADM_SET_SERVER_PRI]     = sub {
    my ($ip, $port, $pri);
    ($ip, $port) = &unpackAddr or return;
    defined($pri  = &unpackB) or return;
    return ($ip, $port, $pri);
};
$packTable[PT_ADM_SET_SERVER_PRI]       = sub {
    my ($ip, $port, $pri) = @_;
    return packAddr($ip, $port) . packB($pri);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_SHARED_FILES] = 'Adm Get shared files';
$unpackTable[PT_ADM_GET_SHARED_FILES]   = $unpackEmpty;
$packTable[PT_ADM_GET_SHARED_FILES]     = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_OPTIONS]      = 'Adm Get options';
$unpackTable[PT_ADM_GET_OPTIONS]        = $unpackEmpty;
$packTable[PT_ADM_GET_OPTIONS]          = $packEmpty;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_DOWNLOAD_FILE]    = 'Adm Download file';
$unpackTable[PT_ADM_DOWNLOAD_FILE]      = \&unpackInfo;
$packTable[PT_ADM_DOWNLOAD_FILE]        = \&packInfo;
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_GAP_DETAILS]  = 'Adm Get gap details';
$unpackTable[PT_ADM_GET_GAP_DETAILS]    = sub {
    my ($hash);
    defined($hash = &unpackHash) or return;
    &unpackB;
    return $hash;
};
$packTable[PT_ADM_GET_GAP_DETAILS]      = sub {
    return &packHash . packB(0);
};
# -------------------------------------------------------------------
$PacketTagName[PT_ADM_GET_CORE_STATUS]  = 'Adm Get core status';
$unpackTable[PT_ADM_GET_CORE_STATUS]    = $unpackEmpty;
$packTable[PT_ADM_GET_CORE_STATUS]      = $packEmpty;

sub unpackGapInfo {
    my ($start, $end, $val);
    defined($start = &unpackD) or return;
    defined($end   = &unpackD) or return;
    defined($val   = &unpackW) or return;
    return {Start => $start, End => $end, Status => $val};
}
sub packGapInfo {
    my ($d) = @_;
    return packD($d->{Start}) . packD($d->{End}) . packW($d->{Status});
}

sub unpackGapInfoList {
    my (@res, $len, $s);
    @res = ();
    defined($len = &unpackW) or return;
    while ($len--) {
        defined($s = &unpackGapInfo) or return;
        push @res, $s;
    }
    return \@res;
}
sub packGapInfoList {
    my ($l) = @_;
    my ($res, $e);
    $res = packW(scalar @$l);
    foreach $e (@$l) {
        $res .= packGapInfo($e);
    }
    return $res;
}

1;
__END__

=head1 NAME

P2P::pDonkey::Packet - Perl extension for handling packets of eDonkey peer2peer protocol. 

=head1 SYNOPSIS

  
    use P2P::pDonkey::Meta qw( makeClientInfo printInfo );
    use P2P::pDonkey::Packet ':all';
    use Data::Hexdumper;

    my $user = makeClientInfo(0, 4662, 'Muxer', 60);
    my $raw = packBody(PT_HELLO, $user);
    print hexdump(data => $raw);

    my ($off, $pt) = (0);
    $user = unpackBody(\$pt, $raw, $off);
    print "Packet type: ", PacketTagName($pt), "\n";
    printInfo($user);

=head1 DESCRIPTION

The module provides functions and constants for creating, packing and 
unpacking packets of eDonkey peer2peer protocol.

=over

=item PacketTagName(PT_TAG)

    Returns string name of PT_TAG or 'Unknown(PT_TAG)' if name is unknown.
    
=item unpackBody(\$pt, $data, $offset)

    Unpacks data and places packet type in $pt. $offset is changed to last 
    unpacked byte offset in $data. Packet header is not processed in 
    unpackBody(), so $offset should be set on packet type byte offset.
    Returns list of unpacked data in success.
    
=item packBody(PT_TAG, ...) 

    Packs user data in packet with PT_TAG type and returns byte string.
    packet header is not included in result.

=item unpackUDPHeader($data, $offset)

    Returns 1 if data starts with PT_HEADER byte.
    
=item packUDPHeader()

    Returns packed PT_HEADER byte.
    
=item unpackTCPHeader($data, $offset)

    Unpacks header and returns length of the following packet body.
    
=item packTCPHeader($length)

    Returns packed header.
    
=back

=head2 eDonkey packet types

    Here listed data, returned by unpackBody() and passed to packBody()
    for each packet type.

=over

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Alexey Klimkin, E<lt>klimkin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>, L<P2P::pDonkey::Meta>.

eDonkey home:

=over 4

    <http://www.edonkey2000.com/>

=back

Basic protocol information:

=over 4

    <http://hitech.dk/donkeyprotocol.html>

    <http://www.schrevel.com/edonkey/>

=back

Client stuff:

=over 4

    <http://www.emule-project.net/>

    <http://www.nongnu.org/mldonkey/>

=back

Server stuff:

=over 4

    <http://www.thedonkeynetwork.com/>

=back

=cut

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
use POSIX qw(floor);
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Util ':all';
use P2P::pDonkey::Packet ':all';
use P2P::pDonkey::Met qw(:server :part);
use Data::Hexdumper;
use File::Glob ':glob';
use ServBase;

use constant SS_REQUESTING  => 0x01;
use constant SS_NOSUCHFILE  => 0x02;
use constant SS_=> 0x02;

my ($debug, $dump) = (1, 0);

# server optionsuration
my %options = (
              Nickname      => 'Muxer',
              Version       => 60,
              incomingPort  => 4665,
              adminDoorPort => 4663,
              adminName     => 'Muxer',
              adminPass     => 'qwert',
              maxNumUp      => 5,
              maxCon        => 100,
              userMaxUpF    => 0,
              userMaxDownF  => 0,
#              temp          => '/users/klimkin/incoming',
              temp => '.',
              incoming      => '/users/klimkin/tmp',
              auto          => 1,
              servRemove    => 0,
              pmAllow       => 1,
              saveCor       => 0,
              verifyCancel  => 1,
              cbd           => (((2<<8)|10)<<8)|15, # 2002.10.15
              lineDown      => 0,
              PID           => 0
             );

my $chunkSize = 10*1024;
my $user = makeClientInfo(0, $options{incomingPort}, $options{Nickname}, $options{Version});
my @SharedDirs = ();
my $SharedFiles = [];#makeFileInfoList(@SharedDirs);
my $ServerList = readServerMet('ss.met');
my $Downloads = LoadPartMets($options{temp}); # mapping hash->part
my %Sources; # mapping addr->hash->part

my ($saddr, $port) = ('176.16.4.244', 4661);
#my ($saddr, $port) = ('212.202.199.129', 4661);
#my ($saddr, $port) = ('217.224.233.158', 4661);
#my ($saddr, $port) = ('80.130.53.117', 4661);

my @procTable;
$procTable[PT_HELLO]            = \&processHello;
$procTable[PT_HELLOANSWER]      = \&processHelloAnswer;
$procTable[PT_IDCHANGE]         = \&processIDChange;
$procTable[PT_SERVERMESSAGE]    = \&processServerMessage;
$procTable[PT_SERVERSTATUS]     = \&processServerStatus;
$procTable[PT_SERVERLIST]       = \&processServerList;
$procTable[PT_SERVERINFO]       = \&processServerInfo;
$procTable[PT_SEARCHFILERES]    = \&processSearchFileAnswer;
$procTable[PT_FOUNDSOURCES]     = \&processFoundSources;
$procTable[PT_FILEREQANSWER]    = \&processFileRequestAnswer;
$procTable[PT_NOSUCHFILE]       = \&processNoSuchFile;
$procTable[PT_FILESTATUS]       = \&processFileStatus;
$procTable[PT_HASHSETANSWER]    = \&processHashSetAnswer;

$procTable[PT_SLOTGIVEN]        = \&processSlotGiven;
$procTable[PT_SLOTTAKEN]        = \&processSlotTaken;
$procTable[PT_SENDINGPART]      = \&processSendingPart;

$procTable[PT_ADM_LOGIN]            = \&processAdmLogin;
$procTable[PT_ADM_GET_OPTIONS]      = \&processAdmGetOptions;
$procTable[PT_ADM_START_DL_STATUS]  = \&processAdmStartDLStatus;
$procTable[PT_ADM_START_UL_STATUS]  = \&processAdmStartULStatus;
$procTable[PT_ADM_STOP_DL_STATUS]   = \&processAdmStopDLStatus;
$procTable[PT_ADM_STOP_UL_STATUS]   = \&processAdmStopULStatus;
$procTable[PT_ADM_GET_SERVER_LIST]  = \&processAdmGetServerList;
$procTable[PT_ADM_GET_SHARED_DIRS]  = \&processAdmGetSharedDirs;
$procTable[PT_ADM_GET_SHARED_FILES] = \&processAdmGetSharedFiles;
$procTable[PT_ADM_SEARCH_FILE]      = \&processAdmSearchFile;
$procTable[PT_ADM_EXTEND_SEARCH_FILE]= \&processAdmExtendSearchFile;
$procTable[PT_ADM_DOWNLOAD_FILE]    = \&processAdmDownloadFile;
$procTable[PT_ADM_CANCEL_DOWNLOAD]  = \&processAdmCancelDownload;
$procTable[PT_ADM_GET_GAP_DETAILS]  = \&processAdmGetGapDetails;

my $server = new ServBase(ProxyAddr => '192.168.3.2', ProxyPort => 8080,
                          AdminPort => $options{adminDoorPort},
                          LocalPort => $options{incomingPort},
                          MaxClients => $options{maxNumUp},
                          ProcTable => \@procTable,
                          OnConnect => \&OnConnect,
                          OnDisconnect => \&OnDisconnect,
#                          OnDisconnect => \&RemoveShared,
                          CanReadHook => \&checkIN,
                          Dump => $dump);

my $IN;
$IN = IO::Handle->new_from_fd(fileno(STDIN), 'r');
$IN->blocking(0);
$server->watch($IN);

my ($Nserv, $Ncli) = (0, 0);
my $conn;
#$conn = $server->Connect($saddr, $port) or warn "Connect: $!";
#$conn->{Server} = 1;
#goto n;
foreach my $s (values %$ServerList) {
    $conn = $server->Connect(ip2addr($s->{IP}), $s->{Port});
    if ($conn) {
        $conn->{Server} = 1;
        $Nserv++;
        print "Connected to $Nserv servers\n";
    } else {
       warn "Connect: $!";
    }
}
n:
$server->MainLoop() || die "Can't start server: $!\n";

exit;

my $AdminConn;


sub isClient {
    my ($conn) = @_;
    return 1 if $conn->{Client};
    $server->Disconnect($conn->{Socket});
    return;
}
sub isServer {
    my ($conn) = @_;
    return 1 if $conn->{Server};
    $server->Disconnect($conn->{Socket});
    return;
}
sub isAdmin {
    my ($conn) = @_;
    return 1 if $conn->{Admin};
    $server->Disconnect($conn->{Socket});
    return;
}

sub OnConnect {
    my ($conn) = @_;
    if ($conn->{Client}) {
        $server->Queue($conn, PT_HELLO, $user);
        printInfo($user);
    } elsif ($conn->{Server}) {
        delete $user->{ServerIP};
        $server->Queue($conn, PT_HELLO, $user);
#        $server->Queue($conn, PT_GETSERVERLIST);
        $user->{ServerIP} = $conn->{IP};
        $user->{ServerPort} = $conn->{Port};
#        printInfo($user);
    }
}

sub OnDisconnect {
    my ($conn) = @_;
    if ($conn->{Client}) {
        my $idaddr = idAddr($conn);
        my $f = $Sources{$idaddr}->{Current};
        if ($f) {
            push @{$f->{Part}->{Queue}}, @{$f->{Pending}};
            $f->{Pending} = [];
            delete $Sources{$idaddr}->{Current};
        }
        $Ncli--;
        print "Connected to $Ncli clients\n";
    } elsif ($conn->{Server}) {
        $Nserv--;
        print "Connected to $Nserv servers\n";
    } elsif ($conn->{Admin}) {
        $AdminConn = undef;
    }
}

# admin packets processing
sub processAdmLogin {
    my ($conn, $user, $pass) = @_;
    isAdmin($conn) or return;
    if ($user eq $options{adminName} && $pass eq $options{adminPass}) {
        $AdminConn = $conn;
    } else {
        $AdminConn = undef;
        $server->Disconnect($conn->{Socket});
    }
}
sub processAdmGetOptions {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
    $server->Queue($AdminConn, PT_ADM_OPTIONS, \%options);
}
sub processAdmStartDLStatus {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
}
sub processAdmStartULStatus {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
}
sub processAdmStopDLStatus {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
}
sub processAdmStopULStatus {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
}
sub processAdmGetServerList {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
    $server->Queue($AdminConn, PT_ADM_SERVER_LIST, [values %$ServerList]);
}
sub processAdmGetSharedDirs {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
    $server->Queue($AdminConn, PT_ADM_SHARED_DIRS, \@SharedDirs);
}
sub processAdmGetSharedFiles {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
    $server->Queue($AdminConn, PT_ADM_SHARED_FILES, $SharedFiles);
}
sub processAdmSearchFile {
    my ($conn, $q) = @_;
    isAdmin($conn) && $AdminConn or return;
    $server->Queue('Server', PT_SEARCHFILE, $q);
}
sub processAdmExtendSearchFile {
    my ($conn) = @_;
    isAdmin($conn) && $AdminConn or return;
}
sub processAdmDownloadFile {
    my $conn = shift;
    isAdmin($conn) && $AdminConn or return;
    my ($i) = @_;
    my $part = $Downloads->{$i->{Hash}};
#    if ($part) {
#        warn "already downloading $i->{Hash}\n";
#    } else {
        $i->{Date} = 0;
        $i->{Parts} = [];
        $i->{Gaps} = [0, $i->{Meta}->{Size}->{Value}];
        $i->{Path} = "$options{temp}/$i->{Hash}.part.met";
#        $i->{Path} = "$i->{Hash}.part.met";
        $i->{Meta}->{Copied}    = makeMeta(TT_COPIED, 0);
        $i->{Meta}->{'Temp file'} = makeMeta(TT_TEMPFILE, "$options{temp}/$i->{Hash}.part");
        $i->{Meta}->{Priority}  = makeMeta(TT_PRIORITY, FPRI_NORMAL);
        $i->{Meta}->{Status}    = makeMeta(TT_STATUS, DLS_LOOKING);
        $Downloads->{$i->{Hash}} = $i;
        MakeQueue($i);
        $server->Queue('Server', PT_GETSOURCES, $i->{Hash});
        $server->Queue($AdminConn, PT_ADM_NEW_DOWNLOAD, $i, FPRI_NORMAL, $i->{Meta}->{'Temp file'}->{Value});
#    }
}
sub processAdmCancelDownload {
    my $conn = shift;
    isAdmin($conn) && $AdminConn or return;
    my ($hash) = @_;
    my $part = $Downloads->{$hash};
    $part->{Queue} = [];
    $server->Queue($AdminConn, PT_ADM_REMOVE_DOWNLOAD, $hash);
}
sub processAdmGetGapDetails {
    my $conn = shift;
    isAdmin($conn) && $AdminConn or return;
    my ($hash) = @_;
#    $server->Queue($AdminConn, PT_ADM_GAP_DETAILS, [])
}

# client packets processing
sub processHello {
    my ($conn, $d) = @_;
    isClient($conn) or return;

    $server->Queue($conn, PT_HELLOANSWER, $user);
    printInfo($user);
}
sub processHelloAnswer {
    my ($conn, $d) = @_;
    isClient($conn) or return;
    printInfo($d);
    my $idaddr = idAddr($conn);
    my ($hash, $f);
    while (($hash, $f) = each %{$Sources{$idaddr}}) {
        last;
    }
    if ($f) {
        $server->Queue($conn, PT_FILEREQUEST, $hash);
    }
}
sub processFileRequestAnswer {
    my $conn = shift;
    isClient($conn) or return;
    my ($hash, $fname) = @_;
    my $part = $Downloads->{$hash};
    if ($part) {
        $server->Queue($conn, PT_FILESTATUSREQ, $hash);
        $server->Queue($conn, PT_HASHSETREQUEST, $hash);
        $server->Queue($conn, PT_SLOTREQUEST);
    } else {
        warn "don't need $hash\n";
    }
}
sub processNoSuchFile {
    my $conn = shift;
    isClient($conn) or return;
    my ($hash) = @_;
    my $part = $Downloads->{$hash};
    if ($part) {
        $part->{Sources}->{idAddr($conn)} = SS_NOSUCHFILE;
    } else {
        warn "don't need $hash\n";
    }
}
sub processFileStatus {
    my $conn = shift;
    isClient($conn) or return;
    my ($hash, $status) = @_;
    print "$hash: ", join('', @$status), "\n";
    $Sources{idAddr($conn)}->{$hash}->{Status} = $status;;

}
sub processHashSetAnswer {
    my $conn = shift;
    isClient($conn) or return;
    my ($hash, $parthashes) = @_;
}

sub processSlotGiven {
    my $conn = shift;
    isClient($conn) or return;
    my $idaddr = idAddr($conn);
    my ($f, $part, $hash, $queue, $pending);
#    ($hash, $f) = each %{$Sources{$idaddr}};
    $f = (values %{$Sources{$idaddr}})[0];
#    while (($hash, $f) = each %{$Sources{$idaddr}}) {
#        last;
#    }
    if ($f) {
        my ($status);
        $part   = $f->{Part};
        $pending= $f->{Pending};
        $status = $f->{Status};
        $queue  = $part->{Queue};
        $hash   = $part->{Hash};
        my ($chunks, $need) = (scalar @$queue, 3);
        while ($chunks-- && $need) {
            $_ = shift @$queue or last;
            if ($status->[floor($_->{Start}/SZ_FILEPART)]) {
                push @$pending, $_;
                $need--;
            } else {
                push @$queue, $_;
            }
        }
    } else {
        $pending = [];
    }
    if (@$pending) {
        my @gaps;
        print "$hash: Requesting parts: ";
        foreach (@$pending) {
            push @gaps, $_->{Start}, $_->{End};
            print $_->{Start}, '-', $_->{End}, ' ';
        }
        print "\n";
        $Sources{$idaddr}->{Current} = $f;
        $server->Queue($conn, PT_REQUESTPARTS, $hash, sort {$a <=> $b} @gaps);
    } else {
        $server->Queue($conn, PT_SLOTRELEASE);
#        $server->Queue($conn, PT_ENDOFOWNLOAD, $hash);
        $server->Disconnect($conn->{Socket});
    }
}
sub processSlotTaken {
    my $conn = shift;
    isClient($conn) or return;
    my $idaddr = idAddr($conn);
    my $f = $Sources{$idaddr}->{Current};
    if ($f) {
        push @{$f->{Part}->{Queue}}, @{$f->{Pending}};
        $f->{Pending} = [];
        delete $Sources{$idaddr}->{Current};
    }
#    $server->Queue($conn, PT_SLOTREQUEST);
#    my @chunks = FindAssignedChunks($idaddr);
#    foreach my $c (@chunks) {
#        $c->{$idaddr} = 1;
#    }
}
sub processSendingPart {
    my $conn = shift;
    isClient($conn) or return;
    my ($hash, $start, $end, $data) = @_;
    my $part = $Downloads->{$hash};
    my $meta = $part->{Meta};
    my $idaddr = idAddr($conn);
    my $f = $Sources{$idaddr}->{$hash};
    if ($part) {
        if (!$part->{Handle}) {
            my $tmpfname = $meta->{'Temp file'}->{Value};
            if (-f $tmpfname) {
                open($part->{Handle}, "+<$tmpfname") or die "can't open $tmpfname\n";
            } else {
                open($part->{Handle}, "+>$tmpfname") or die "can't open $tmpfname\n";
                truncate $part->{Handle}, $meta->{Size}->{Value};
            }
        }
        print "$hash: Saving data $start - $end\n";
        seek($part->{Handle}, $start, 0) or warn "$!" and return;
        print {$part->{Handle}} $$data or warn "$!" and return;
        $meta->{Copied}->{Value} += $end - $start;
        TrimChunks($f->{Pending}, $start, $end);
        push @{$part->{Queue}}, @{$f->{Pending}};
        $f->{Pending} = [];
        if (!@{$part->{Queue}} && $meta->{Copied}->{Value} >= $meta->{Size}->{Value}) {
            # finish download
            if ($AdminConn) {
                $server->Queue($AdminConn, PT_ADM_REMOVE_DOWNLOAD, $hash);
            } else {
                print "$hash: finished download\n";
            }
        } else {
            if ($AdminConn) {
                $server->Queue($AdminConn, PT_ADM_DOWNLOAD_STATUS, [{
                               Slot => 0,
                               Status => DLS_DOWNLOADING,
                               Speed => 0,
                               Transferred => $meta->{Copied}->{Value},
                               Availability => 64,
                               Sources => 1
                               }]);
            }
        }
    } else {
        warn "don't need any parts for $hash\n";
    }
}

# server packets processing
sub processIDChange {
    my ($conn, $id) = @_;
    isServer($conn) or return;

    $user->{IP} = $id;
    print "\tnew ClientID: $id\n";

    foreach my $info (@$SharedFiles) {
        $info->{IP}   = $user->{IP};
        $info->{Port} = $user->{Port};
    }
    
    $server->Queue($conn, PT_GETSERVERLIST);
#    $server->Queue($conn, PT_OFFERFILES, $shared);
}

sub processServerMessage {
    my $conn = shift;
    isServer($conn) or return;
    if ($AdminConn) {
#        $server->Queue($AdminConn, PT_ADM_MESSAGE, @_);
    } else {
        my ($msg) = @_;
#        print "$msg\n";
    }
}

sub processServerStatus {
    my $conn = shift;
    isServer($conn) or return;

    if ($AdminConn) {
        $server->Queue($AdminConn, PT_ADM_SERVER_STATUS, @_);
    } else {
        my ($users, $files) = @_;
        print "\tUsers: $users, Files: $files\n";
    }
}

sub processServerList {
    my (undef, $d) = @_;
    isServer($conn) or isClient($conn) or return;

#    my $snum = @$d/2;
#    print "\tGot $snum servers:\n";
#    for (my $i = 0; $i < $snum; $i++) {
    my $nservnew = 0;
    while (@$d) {
        my ($ip, $port, $conn);
        $ip   = shift @$d;
        $port = shift @$d;
        next;
        next if $ServerList->{idAddr($ip, $port)};
        $nservnew++;
        $ServerList->{idAddr($ip, $port)} = makeServerDesc($ip, $port);
        $conn = $server->Connect(ip2addr($ip), $port);
        if ($conn) {
            $conn->{Server} = 1;
            $Nserv++;
            print "Connected to $Nserv servers\n";
        } else {
            warn "Connect: $!";
        }
    }
#    print "$nservnew new servers\n";
}

sub processServerInfo {
    my ($conn, $info) = @_;
    isServer($conn) or return;
    printInfo($info, 1);
}

sub processSearchFileAnswer {
    my ($conn, $d, $more) = @_;
    isServer($conn) or return;
    
    if ($AdminConn) {
        $server->Queue($AdminConn, PT_ADM_SEARCH_FILE_RES, $d, $more);
    } else {
        foreach my $res (@$d) {
            printInfo($res, 0);
        }
    }
}
sub processFoundSources {
    my $conn = shift;
    isServer($conn) or return;
    my ($hash, $addrl) = @_;
    my $part = $Downloads->{$hash};
    if ($part) {
        my ($ip, $port, $conn);
        while (@$addrl) {
            ($ip, $port) = (shift @$addrl, shift @$addrl);
            my $idaddr = idAddr($ip, $port);
            next if $Sources{$idaddr}->{$hash}; # already have that source
            # check is there connection to that host
            $conn = $server->connections->{$idaddr};
            if (!$conn) {
                $conn = $server->Connect(ip2addr($ip), $port) or warn "Connect: $!";;
                next unless $conn;
                $Ncli++;
                print "Connected to $Ncli clients\n";
                $conn->{Client} = 1;
            } 
            # request file from host
            $Sources{$idaddr} or $Sources{$idaddr} = {};
            $Sources{$idaddr}->{$hash} = {Part => $part,
                                          Pending => []};
        }
    } else {
        warn "don't need any sources for $hash\n";
    }
}

# process console input
sub checkIN {
    my ($h) = @_;
    my $cmd;

    if ($h == $IN) {
        $cmd = $IN->getline;
    } else {
        return;
    }


    SWITCH: {
        if (!defined $cmd || $cmd =~ /^(q|quit)$/) {
#            WriteServerMet('ss.met', \%servers);
            OnExit();
            exit;
        }
        
        if ($cmd =~ /^(s|search)\s+(.*)\s+(-(\W+))?$/) {
            my ($req, $ft) = ($2, $4);
            $server->Queue(undef, PT_SEARCHFILE, {Type => ST_NAME, Value => $req});
            last SWITCH;
        }

        if ($cmd =~ /^c ([^:]*):(\d*)$/) {
            $server->Connect($1, $2) || warn "Connect: $!";;
            last SWITCH;
        }

        if ($cmd =~ /^cc ([^:]*):(\d*)$/) {
            my $conn;
            $conn = $server->Connect($1, $2) or warn "Connect: $!";;
            $conn->{Client} = 1;
            last SWITCH;
        }

        if ($cmd =~ /^vf$/) {
            $server->Queue(undef, PT_VIEWFILES);
            last SWITCH;
        }

        if ($cmd =~ /^msg (.*)$/) {
            $server->Queue(undef, PT_MESSAGE, $1);
            last SWITCH;
        }

        if ($cmd =~ /^t$/) {
#            my @unk = (0x2,0x3,0x4,
#                       0x17,
#                       0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,0x30,0x31,
#                       0x44,0x45);
#            my @unk = (0x53);
            my @unk = (0x39);
            foreach my $pt (@unk) {
                print "$pt:\n";
                $server->Queue(undef, $pt);
            }
            last SWITCH;
        }

        if ($cmd =~ /^stat$/) {
            print "Servers: $Nserv, Clients: $Ncli\n";
            last SWITCH;
        }
        
        if ($cmd =~ /^\?$/) {
            print <<END;
Commands:
    c  IP:Port      Connect to server
    cc IP:Port      Connect to client
    vf              View files of peer clients
    s  String       Search files by name
    q               Quit
END
            last SWITCH;
        }
        
        print "Unknown command\n";
    }
    #    my $cmd = $term->readline($prompt);
    #    defined($cmd) || exit;
    return 1;
}

# functions work with Downloads 
sub LoadPartMets {
    my ($dir) = @_;
    my (%res, $i);
    foreach my $path (bsd_glob("$dir/*.part.met", GLOB_TILDE)) {
        $i = readPartMet($path);
        if ($i) {
            if ($res{$i->{Hash}}) {
                warn "already have file\n";
                printInfo($i);
            } else {
                $res{$i->{Hash}} = $i;
                MakeQueue($i);
            }
        } else {
            warn "can't read file: $path\n";
        }
    }
    $Downloads = \%res;
}
sub SavePartMet {
    my ($part) = @_;
    my @gaps = ();
    foreach my $chunk (@{$part->{Queue}}) {
        push @gaps, $chunk->{Start}, $chunk->{End};
    }
    my %seen = ();
    foreach (@gaps) {
        $seen{$_}++;
    }
    @{$part->{Gaps}} = sort {$a <=> $b} grep {$seen{$_} == 1} keys %seen;
    writePartMet($part->{Path}, $part) or warn "can't write file: $part->{Path}\n";
}

sub OnExit {
    foreach my $c (values %{$server->connections}) {
        $server->Disconnect($c->{Socket});
    }
    foreach my $p (values %$Downloads) {
        close($p->{Handle}) if $p->{Handle};
        SavePartMet($p);
    }
    writeServerMet('ss.met',  $ServerList); 
}

# chunks queue
sub MakeQueue {
    my ($p) = @_;
    my (@gaps, @queue);
    @gaps = @{$p->{Gaps}};
    while (@gaps) {
        my ($start, $end) = (shift @gaps, shift @gaps);
        while ($start < $end) {
            my %chunk;
            $chunk{Start} = $start;
            $start += $chunkSize;
            $chunk{End} = $start < $end ? $start : $end;
            push @queue, \%chunk;
        }
    }
    $p->{Queue} = \@queue;
}

# Chunk  [============)
# 1. [-)
# 2. [------)
# 3. [--------------------)
# 4.        [------)
# 5.               [------)
# 6.                    [-)
sub TrimChunks {
    my ($queue, $start, $end) = @_;
    $queue && @$queue or return;
    my @newq = ();
    foreach my $chunk (@$queue) {
        if ($start <= $chunk->{Start}) {
            if ($end <= $chunk->{Start}) {
                # 1. leave as is
            } elsif ($end < $chunk->{End}) {
                # 2. trim start
                $chunk->{Start} = $end;
            } else {
                # 3. whole chunk downloaded
                next;
            }
        } elsif ($start < $chunk->{End}) {
            if ($end < $chunk->{End}) {
                # 4. chunk is split in two
                my %nchunk = %$chunk;
                $chunk->{End} = $start;
                $nchunk{Start} = $end;
                push @newq, \%nchunk;
            } else {
                # 5. trim end
                $chunk->{End} = $start;
            }
        } else {
            # 6. leave as is
        }
        push @newq, $chunk;
    }
    @$queue = @newq;
}


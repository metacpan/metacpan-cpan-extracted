package MooseFS::Disk;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS::Server';

has HDtime => (
    is => 'ro',
    default => sub { 'max' }
);

has HDperiod => ( 
    is => 'ro',
    default => sub { 'min' }
);

sub BUILD {
    my $self = shift;
    my $inforef;
    for my $ip ( keys %{ $self->info } ) {
        my $port = $self->info->{$ip}->{port};
        my $ns = IO::Socket::INET->new(
            PeerAddr => $ip,
            PeerPort => $port,
            Proto => 'tcp',
        );
        print $ns pack('(LL)>', 600, 0);
        my $nheader = $self->myrecv($ns, 8);
        my ($ncmd, $nlength) = unpack('(LL)>', $nheader);
        if ( $ncmd == 601 ) {
            my $data = $self->myrecv($ns, $nlength);
            while ( $nlength > 0 ) {
                my ($entrysize) = unpack("S>", substr($data, 0, 2));
                my $entry = substr($data, 2, $entrysize);
                $data = substr($data, 2+$entrysize);
                $nlength -= 2 + $entrysize;
            
                my $plen = ord(substr($entry, 0, 1));
                my $ip_path = sprintf "%s:%u:%s", $ip, $port, substr($entry, 1, $plen);
                my ($flags, $errchunkid, $errtime, $used, $total, $chunkscnt) = unpack("(CQLQQL)>", substr($entry, $plen+1, 33));
                my ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax);

                if ($entrysize == $plen + 34 + 144 ) {
            
                    if ($self->HDperiod eq 'min' ) {
                        ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $rops, $wops, $usecreadmax, $usecwritemax) = unpack("(QQQQLLLL)>", substr($entry, $plen+34, 48));
                    } elsif ($self->HDperiod eq 'hour') {
                        ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $rops, $wops, $usecreadmax, $usecwritemax) = unpack("(QQQQLLLL)>", substr($entry, $plen+34+48, 48));
                    } elsif ($self->HDperiod eq 'day') {
                        ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $rops, $wops, $usecreadmax, $usecwritemax) = unpack("(QQQQLLLL)>", substr($entry, $plen+34+48+48, 48));
                    }
            
                } elsif ( $entrysize == $plen + 34 + 192 ) {
            
                    if ($self->HDperiod eq 'min' ) {
                        ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax) = unpack("(QQQQQLLLLLL)>", substr($entry, $plen+34, 64));
                    } elsif ($self->HDperiod eq 'hour') {
                        ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax) = unpack("(QQQQQLLLLLL)>", substr($entry, $plen+34+64, 64));
                    } elsif ($self->HDperiod eq 'day') {
                        ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax) = unpack("(QQQQQLLLLLL)>", substr($entry, $plen+34+64+64, 64));
                    }
            
                }
            
                my ($rtime, $wtime, $fsynctime);
                if ($self->HDtime eq 'avg') {
                    if ($rops > 0) {
                        $rtime = $usecreadsum/$rops;
                    } else {
                        $rtime = 0;
                    };
            
                    if ($wops > 0) {
                        $wtime = $usecwritesum/$wops;
                    } else {
                        $wtime = 0;
                    };
            
                    if ($fsyncops > 0) {
                        $fsynctime = $usecfsyncsum/$fsyncops;
                    } else {
                        $fsynctime = 0;
                    };
                } else {
                    $rtime = $usecreadmax;
                    $wtime = $usecwritemax;
                    $fsynctime = $usecfsyncmax;
                };
            
                my $status;
                if ($flags == 1) {
                    $status = 'marked for removal';
                } elsif ($flags == 2) {
                    $status = 'damaged';
                } elsif ($flags == 3) {
                    $status = 'damaged, marked for removal';
                } else {
                    $status = 'ok';
                };
            
                my $lerror;
                if ($errtime == 0 and $errchunkid == 0) {
                    $lerror = 'no errors';
                } else {
                    $lerror = localtime($errtime);
                };
            
                my $rbsize = $rops > 0 ? $rbytes / $rops : 0;
                my $wbsize = $wops > 0 ? $wbytes / $wops : 0;
                my $percent_used = $total > 0 ? ($used * 100.0) / $total : '-';
                my $rbw = $usecreadsum > 0 ? $rbytes * 1000000 / $usecreadsum : 0;
                my $wbw = $usecwritesum + $usecfsyncsum > 0 ? $wbytes *1000000 / ($usecwritesum + $usecfsyncsum) : 0;
            
                $self->info->{$ip} = {
                    ip_path => $ip_path,
                    flags => $flags,
                    errchunkid => $errchunkid,
                    errtime => $errtime,
                    used => $used,
                    total => $total,
                    chunkscount => $chunkscnt,
                    rbw => $rbw,
                    wbw => $wbw,
                    rtime => $rtime,
                    wtime => $wtime,
                    fsynctime => $fsynctime,
                    read_ops => $rops,
                    write_ops => $wops,
                    fsyncops => $fsyncops,
                    read_bytes => $rbytes,
                    write_bytes => $wbytes,
                    usecreadsum => $usecreadsum,
                    usecwritesum => $usecwritesum,
                    status => $status,
                    lerror => $lerror,
                    rbsize => $rbsize,
                    wbsize => $wbsize,
                    percent_used => $percent_used,
                };
            };
        }
        close($ns);
    }
}

1;

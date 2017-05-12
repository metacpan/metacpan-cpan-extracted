package MooseFS::Operations;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

has list => (
    is => 'rw',
    default => sub { [] }
);

sub BUILD {
    my $self = shift;
    my $ver = $self->masterversion;
    my $s = $self->sock;

    print $s pack('(LL)>', 508, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    if ( $cmd == 509 and $ver > 1514 ) {
        my $data = $self->myrecv($s, $length);
        my ($startcnt, $pos);

        if ($ver < 1621 ) {
            $startcnt = 16;
            $pos = 0;
        } elsif ($ver == 1621) {
            $startcnt = 21;
            $pos = 0;
        } else {
            $startcnt = (unpack("S>", substr($data, 0, 2)))[0];
            $pos = 2;
        };

        while ( $pos < $length ) {
            my ($sessionid, $ip1, $ip2, $ip3, $ip4, $v1, $v2, $v3, $ileng) = unpack("(LCCCCSCCL)>", substr($data, $pos, 16));
            $pos += 16;
            my $info = substr($data, $pos, $ileng);
            $pos += $ileng;
            my $pleng = (unpack("L>", substr($data, $pos, 4)))[0];
            $pos += 4;
            my $path = substr($data, $pos, $pleng);
            $pos += $pleng;

            if ( $ver >= 1600 ) {
                $pos += 17;
            } else {
                $pos += 9;
            };

            my (@stats_c, @stats_l);
            if ($startcnt < 16) {
                        @stats_c = unpack("(L$startcnt)>", substr($data, $pos,4*$startcnt));
                        $pos += $startcnt * 4;
                        @stats_l = unpack("(L$startcnt)>", substr($data, $pos,4*$startcnt));
                        $pos += $startcnt * 4;
            } else {
                        @stats_c = unpack("(L16)>", substr($data, $pos, 64));
                        $pos += $startcnt * 4;
                        @stats_l = unpack("(L16)>", substr($data, $pos, 64));
                        $pos += $startcnt * 4;
            };

            push @{$self->list}, {
                sessionid =>     $sessionid,
                ip =>            "$ip1.$ip2.$ip3.$ip4",
                info =>          $info,
                ver =>           "$v1.$v2.$v3",
                stats_current => {
                    statfs =>   $stats_c[0],
                    getattr =>  $stats_c[1],
                    setattr =>  $stats_c[2],
                    lookup =>   $stats_c[3],
                    mkdir =>    $stats_c[4],
                    rmdir =>    $stats_c[5],
                    symlink =>  $stats_c[6],
                    readlink => $stats_c[7],
                    mknod =>    $stats_c[8],
                    unlink =>   $stats_c[9],
                    rename =>   $stats_c[10],
                    link =>     $stats_c[11],
                    readdir =>  $stats_c[12],
                    open =>     $stats_c[13],
                    read =>     $stats_c[14],
                    write =>    $stats_c[15],
                },
                stats_lasthour => {
                    statfs =>   $stats_l[0],
                    getattr =>  $stats_l[1],
                    setattr =>  $stats_l[2],
                    lookup =>   $stats_l[3],
                    mkdir =>    $stats_l[4],
                    rmdir =>    $stats_l[5],
                    symlink =>  $stats_l[6],
                    readlink => $stats_l[7],
                    mknod =>    $stats_l[8],
                    unlink =>   $stats_l[9],
                    rename =>   $stats_l[10],
                    link =>     $stats_l[11],
                    readdir =>  $stats_l[12],
                    open =>     $stats_l[13],
                    read =>     $stats_l[14],
                    write =>    $stats_l[15],
                },
            };
        }
    }
}

1;

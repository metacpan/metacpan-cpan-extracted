package MooseFS::Mounts;
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

    if ($ver > 1626) {
        print $s pack('(LLC)>', 508, 1, 1);
    } else {
        print $s pack('(LL)>', 508, 0);
    }

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

            my ($sesflags, $rootuid, $rootgid, $mapalluid, $mapallgid, $mingoal, $maxgoal, $mintrashtime, $maxtrashtime);
            if ($ver >= 1626) {
                ($sesflags, $rootuid, $rootgid, $mapalluid, $mapallgid, $mingoal, $maxgoal, $mintrashtime, $maxtrashtime) = unpack("(CLLLLCCLL)>", substr($data, $pos, 27));
                $pos += 27;
                if ($mingoal <= 1 and $maxgoal >= 9) {
                    $mingoal = undef;
                    $maxgoal = undef;
                };
                if ($mintrashtime == 0 and $maxtrashtime == 0xFFFFFFFF) {
                    $mintrashtime = undef;
                    $maxtrashtime = undef;
                };
            } elsif ($ver > 1600) {
                ($sesflags, $rootuid, $rootgid, $mapalluid, $mapallgid) = unpack("(CLLLL)>", substr($data, $pos, 17));
                $mingoal = undef;
                $maxgoal = undef;
                $mintrashtime = undef;
                $maxtrashtime = undef;
                $pos += 17;
            } else {
                ($sesflags, $rootuid, $rootgid) = unpack("(CLL)>", substr($data, $pos, 9));
                $mapalluid = 0;
                $mapallgid = 0;
                $mingoal = undef;
                $maxgoal = undef;
                $mintrashtime = undef;
                $maxtrashtime = undef;
                $pos += 9;
            };
            $pos += 8 * $startcnt;

            push @{$self->list}, {
                sessionid =>     $sessionid,
                ip =>            "$ip1.$ip2.$ip3.$ip4",
                mount =>         $info,
                version =>       "$v1.$v2.$v3",
                meta =>          $path eq '.' ? 1 : 0,
                moose_path =>    $path,
                ses_flags =>     $sesflags,
                root_uid =>      $rootuid,
                root_gid =>      $rootgid,
                all_users_uid => $mapalluid,
                all_users_gid => $mapallgid,
                mingoal =>       $mingoal,
                maxgoal =>       $maxgoal,
                mintrashtime =>  $mintrashtime,
                maxtrashtime =>  $maxtrashtime,
            };
        }
    }
}

1;

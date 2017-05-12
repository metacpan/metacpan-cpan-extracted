package MooseFS::Exports;
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
    my $s = $self->sock;
    print $s pack('(LL)>', 520, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    if ( $cmd == 521 ) {
        my $data = $self->myrecv($s, $length);
        my $pos = 0;
        while ( $pos < $length ) {
            my ($fip1, $fip2, $fip3, $fip4, $tip1, $tip2, $tip3, $tip4, $pleng) = unpack("(CCCCCCCCL)>", substr($data, $pos, 12));
            $pos += 12;
            my $path = substr($data, $pos, $pleng);
            $pos += $pleng;
            my ($v1, $v2, $v3, $exportflags, $sesflags, $rootuid, $rootgid, $mapalluid, $mapallgid) = unpack("(SCCCCLLLL)>", substr($data, $pos, 22));
            $pos += 22;

            if ( ($sesflags & 16) == 0) {
                $mapalluid = undef;
                $mapallgid = undef;
            };

            push @{$self->list}, {
                ip_range_from => "$fip1.$fip2.$fip3.$fip4",
                ip_range_to =>   "$tip1.$tip2.$tip3.$tip4",
                path =>          $path,
                meta =>          $path eq '.' ? 1 : 0,
                version =>       "$v1.$v2.$v3",
                export_flags =>  $exportflags,
                ses_flags =>     $sesflags,
                root_uid =>      $rootuid,
                root_gid =>      $rootgid,
                all_users_uid => $mapalluid,
                all_users_gid => $mapallgid,
            };
        }
    }
}

1;

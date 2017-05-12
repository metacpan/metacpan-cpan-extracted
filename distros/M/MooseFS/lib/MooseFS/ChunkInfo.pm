package MooseFS::ChunkInfo;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

sub BUILD {
    my $self = shift;
    my $s = $self->sock;
    print $s pack('(LL)>', 514, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    if ( $cmd == 515 and $length == 52 or $length == 76 ) {
        my $data = $self->myrecv($s, $length);
        my $d = substr($data, 0, 52);
        my ($loopstart, $loopend, $del_invalid, $ndel_invalid, $del_unused, $ndel_unused, $del_dclean, $ndel_dclean, $del_ogoal, $ndel_ogoal, $rep_ugoal, $nrep_ugoal, $rebalance) = unpack('(LLLLLLLLLLLLL)>', $d);
        $self->info({
            loop_start => $loopstart,
            loop_end => $loopend,
            invalid_deletions => $del_invalid,
            invalid_deletions_out_of => $del_invalid+$ndel_invalid,
            unused_deletions => $del_unused,
            unused_deletions_out_of => $del_unused+$ndel_unused,
            disk_clean_deletions => $del_dclean,
            disk_clean_deletions_out_of => $del_dclean+$ndel_dclean,
            over_goal_deletions => $del_ogoal,
            over_goal_deletions_out_of => $del_ogoal+$ndel_ogoal,
            replications_under_goal => $rep_ugoal,
            replications_under_goal_out_of => $rep_ugoal+$nrep_ugoal,
            replocations_rebalance => $rebalance,
        });
    }
    for my $key ( keys %{ $self->info } ) {
        has $key => (is => 'ro', lazy => 1, default => sub {$self->info->{$key}} );
    };
}

1;

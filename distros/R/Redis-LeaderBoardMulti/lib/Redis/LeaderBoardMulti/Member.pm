package Redis::LeaderBoardMulti::Member;

use 5.010;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        %args,
    }, $class;
}

sub leader_board { shift->{leader_board} }
sub member { shift->{member} }

sub score {
    my ($self, $score) = @_;

    return $self->leader_board->get_score($self->member) unless $score;

    $self->leader_board->set_score($self->member, $score);
    $score;
}

sub incr {
    my ($self, $score) = @_;
    $score = defined $score ? $score : 1;

    $self->leader_board->incr_score($self->member, $score);
}

sub decr {
    my ($self, $score) = @_;
    $score = defined $score ? $score : 1;

    $self->leader_board->decr_score($self->member, $score);
}

sub rank_with_score {
    my $self = shift;
    $self->leader_board->get_rank_with_score($self->member);
}

sub rank {
    my $self = shift;
    $self->leader_board->get_rank($self->member);
}

sub sorted_order {
    my $self = shift;

    $self->leader_board->sorted_order($self->member);
}

1;

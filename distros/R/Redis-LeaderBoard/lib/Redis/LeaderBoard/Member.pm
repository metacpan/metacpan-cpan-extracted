package Redis::LeaderBoard::Member;
use Mouse;

has leader_board => (
    is       => 'ro',
    isa      => 'Redis::LeaderBoard',
    required => 1,
);

has member => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

no Mouse;

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
__END__

=encoding utf-8

=head1 NAME

Redis::LeaderBoard::Member - leader board member of Redis::LeaderBoard

=head1 SYNOPSIS

    my $leader_board = Redis::LeaderBoard->new(
        redis => $redis,
        key   => 'leader_board:1',
    );

    # Redis::LeaderBoard::Member object
    my $member = $leader_board->find_member('two');
    $member->score(90);
    my $rank = $member->rank;

=head1 DESCRIPTION

Redis::LeaderBoard::Member is member object of Redis::LeaderBoard.

=head1 INTERFACE

=head2 Methods

=head3 C<< $score = $member->score([$score: Number]) >>

set or get score.

=head3 C<< $score = $member->incr([$incr_score: Number]) >>

increment score and returns reflected score. 1 is default C<$increment_score>.

=head3 C<< $score = $member->decr([$decr_score: Number]) >>

decrement score and returns reflected score. 1 is default C<$decrement_score>.

=head3 C<< ($rank:Int, $score:Number) = $member->rank_with_score >>

Returns rank and score.

=head3 C<< $rank:Int = $member->rank >>

Retruns rank.

=head3 C<< $order:Int = $member->sorted_order >>

Get sorted order in sorted set. (same as C<< $redis->zrank >>)

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut



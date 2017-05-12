package Redis::LeaderBoard;
use 5.008001;
our $VERSION = "1.11";
use Mouse;
use Mouse::Util::TypeConstraints;
use Redis::LeaderBoard::Member;

has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has redis => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

enum 'Redis::LeaderBoard::Order' => qw/asc desc/;
has order => (
    is      => 'ro',
    isa     => 'Redis::LeaderBoard::Order',
    default => 'desc',
);

has is_asc => (
    is   => 'ro',
    isa  => 'Bool',
    lazy => 1,
    default => sub { shift->order eq 'asc' },
);

has expire_at => (
    is   => 'ro',
    isa  => 'Int',
);

has limit => (
    is  => 'ro',
    isa => 'Int',
);

no Mouse;

sub find_member {
    my ($self, $member) = @_;

    Redis::LeaderBoard::Member->new(
        member       => $member,
        leader_board => $self,
    );
}

sub set_score {
    my ($self, @member_and_scores) = @_;
    @member_and_scores = reverse @member_and_scores;
    $self->redis->zadd($self->key, @member_and_scores);
    $self->_set_expire_and_limit;
}

sub get_score {
    my ($self, $member) = @_;
    $self->redis->zscore($self->key, $member);
}

sub incr_score {
    my ($self, $member, $score) = @_;
    $score = defined $score ? $score : 1;

    my $ret = $self->redis->zincrby($self->key, $score, $member);
    $self->_set_expire_and_limit;
    $ret;
}

sub decr_score {
    my ($self, $member, $score) = @_;
    $score = defined $score ? $score : 1;

    my $ret = $self->redis->zincrby($self->key, -$score, $member);
    $self->_set_expire_and_limit;
    $ret;
}

sub _set_expire_and_limit {
    my $self = shift;
    $self->redis->expireat($self->key, $self->expire_at) if $self->expire_at;

    if ($self->limit) {
        my ($from, $to) = (0, -$self->limit-1);
        if ($self->is_asc) {
            ($from, $to) = ($self->limit, -1)
        }
        $self->redis->zremrangebyrank($self->key, $from, $to);
    }
}

sub remove {
    my ($self, @members) = @_;

    $self->redis->zrem($self->key, @members);
}

sub get_sorted_order {
    my ($self, $member) = @_;

    my $method = $self->is_asc ? 'zrank' : 'zrevrank';
    $self->redis->$method($self->key, $member);
}

sub get_rank_with_score {
    my ($self, $member) = @_;
    my $redis = $self->redis;

    my $score = $self->get_score($member);
    return unless defined $score;

    my $rank = $self->get_rank_by_score($score);
    ($rank, $score);
}

sub get_rank {
    my ($self, $member) = @_;

    my ($rank) = $self->get_rank_with_score($member);
    $rank;
}

sub rankings {
    my ($self, %args) = @_;
    my $limit  = exists $args{limit}  ? $args{limit}  : $self->member_count;
    my $offset = exists $args{offset} ? $args{offset} : 0;

    my $range_method = $self->is_asc ? 'zrange' : 'zrevrange';

    my $members_with_scores = $self->redis->$range_method($self->key, $offset, $offset + $limit - 1, 'WITHSCORES');
    return [] unless @$members_with_scores;

    my @rankings;
    my ($current_rank, $current_target_score, $same_score_members);
    while (my ($member, $score) = splice @$members_with_scores, 0, 2) {
        if (!$current_rank) {
            $current_rank         = $self->get_rank_by_score($score);
            $same_score_members   = $offset - $current_rank + 2;
            $current_target_score = $score;
        }
        elsif ($score == $current_target_score) {
            $same_score_members++;
        }
        else {
            $current_target_score = $score;
            $current_rank = $current_rank + $same_score_members;
            $same_score_members = 1;
        }
        push @rankings, +{
            member => $member,
            score  => $score,
            rank   => $current_rank,
        };
    }

    \@rankings;
}

sub get_rank_by_score {
    my ($self, $score) = @_;

    my ($min, $max) = $self->is_asc ? ('-inf', "($score") : ("($score", 'inf');
    return $self->member_count($min, $max) + 1;
}

sub member_count {
    my ($self, $from, $to) = @_;

    if (!$from && !$to) {
        $self->redis->zcard($self->key);
    }
    else {
        $from = defined $from ? $from : '-inf';
        $to   = defined $to   ? $to   : 'inf';
        $self->redis->zcount($self->key, $from, $to);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Redis::LeaderBoard - leader board using Redis

=head1 SYNOPSIS

    use Redis;
    use Redis::LeaderBoard;
    my $redis = Redis->new;
    my $lb = Redis::LeaderBoard->new(
        redis => $redis,
        key   => 'leader_board:1',
        order => 'asc', # asc/desc, desc as default
    );
    $lb->set_score('one' => 100');
    $lb->set_score('two' =>  50');
    my ($rank, $score) = $lb->get_rank_with_score('one');

    # memmber object
    my $member = $lb->find_member('two');
    $member->score(90);
    my $rank2 = $member->rank;

=head1 DESCRIPTION

Redis::LeaderBoard is for providing leader board by using Redis's sorted set.

z(rev)?rank of Redis 2.8 or older doesn't consider same scores.
This module resolve it.

=head1 INTERFACE

=head2 Constructor

=head3 C<< my $lb = Redis::LeaderBoard->new(%options) >>

Create a new leader board object. Options should be set in C<%options>.

=over

=item C<redis: Redis>

Redis object. Redis.pm or Redis::hiredis.

=item C<key: Str>

Required.

=item C<order: Enum(asc/desc)>

Optional. C<desc> as default.

=back

=head2 Methods

=head3 C<< $member_obj:Redis::LeaderBoard::Member = $lb->find_member($member:Str) >>

Find member by member id. see L<Redis::LeaderBoard::Member> for more details.

=head3 C<< $lb->set_score($member:Str, $score:Number, [$member2, $score2,...]) >>

Set scores of members. You can set multiple element if using Redis 2.4 or later.

=head3 C<< $score:Number = $lb->get_score($member:Str) >>

Get score of member.

=head3 C<< $score:Number = $lb->incr_score($member:Str, [$increment_score:Number]) >>

increment score of member and returns reflected score. 1 is default C<$increment_score>.

=head3 C<< $score:Number = $lb->decr_score($member:Str, [$decrement_score:Number]) >>

decrement score of member and returns reflected score. 1 is default C<$decrement_score>.

=head3 C<< $lb->remove($member:Str, [$member2:Str,...]) >>

remove members from leader board. Multiple element can be accepted Redis 2.4 or later.

=head3 C<< ($rank:Int, $score:Number) = $lb->get_rank_with_score($member:Str) >>

Returns rank and score. If you want to get rank and score at the same time,
you should not call C<get_score> and C<get_rank> separately, use this method instead for
performance.

=head3 C<< $rank:Int = $lb->get_rank($member:Str) >>

Get rank of member.

=head3 C<< $order:Int = $lb->get_sorted_order($member:Str) >>

Get sorted order in sorted set. (same as C<< $redis->zrank >>)

=head3 C<< $count = $lb->member_count([$from, $to]) >>

Get number of members. If score range (C<$from> and C<$to>) is specified, it returns a number
of members in range.

=head3 C<< $rankings:ArrayRef<HashRef> = $lb->rankings(%opt) >>

Return rankings by arrayref contains hashrefs.
keys of hashref is C<member:Str>, C<rank:Int> and C<score:Number>.

Options can be set in C<%options>. keys of options are as follows.

=over

=item C<limit: Int>

=item C<offset: Int>

=back

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut


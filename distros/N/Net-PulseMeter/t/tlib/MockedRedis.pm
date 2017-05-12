package MockedRedis;
use strict;
use warnings 'all';

use base qw/Test::Mock::Redis/;
use Data::Dumper;

sub multi {};
sub exec {};

sub zadd {
    my ($self, $key, $score, $member) = @_;

    $self->{data}->{$key}->{raw} ||= [];
    push(@{$self->{data}->{$key}->{raw}}, [$score, $member]);

    $self->{data}->{$key}->{by_score}->{$score} ||= [];
    push(@{$self->{data}->{$key}->{by_score}->{$score}}, $member);
}

sub zrange {
    my ($self, $key, $start, $stop, $withscores) = @_;
    
    die("only ZRANGE myzset 0 -1 WITHSCORES is stubbed. ZRANGE $key, $start, $stop, $withscores passed") unless (
        (0 == $start) &&
        (-1 == $stop) &&
        $withscores
    );

    my @data = sort {$a->[0] <=> $b->[0]} @{$self->{data}->{$key}->{raw}};
    return map {reverse @$_} @data;
}

sub zremrangebyrank {
    my ($self, $key, $start, $stop) = @_;
    my $data = $self->{data}->{$key}->{by_score};
    my @scores = sort {$a <=> $b} keys(%$data);

    die("only negative stop stubbed for zremrangebyrank") unless $stop < 0;
    my $l = scalar(@scores) + $stop - $start + 1;
    splice(@scores, $start, $l);

    my @pairs;
    for (@scores) {
        my $score = $_;
        for (@{$self->{data}->{$key}->{by_score}->{$score}}) {
            push @pairs, [$score, $_];
        }
    }
    $self->{data}->{$key} = undef;
    $self->zadd($key, @$_) for @pairs;
}

1;

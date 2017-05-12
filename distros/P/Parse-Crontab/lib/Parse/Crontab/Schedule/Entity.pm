package Parse::Crontab::Schedule::Entity;
use 5.008_001;
use strict;
use warnings;

use overload (
    q{""}    => 'stringify',
);

use List::MoreUtils qw/uniq/;

use Mouse;

has entity => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has field => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has range => (
    is       => 'ro',
    isa      => 'ArrayRef[Int]',
    required => 1,
);

has map => (
    is       => 'ro',
    isa      => 'HashRef',
);

has range_min => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    default  => sub {shift->range->[0]},
);

has range_max => (
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    default  => sub {shift->range->[1]},
);

has expanded => (
    is       => 'rw',
    isa      => 'ArrayRef[Int]',
);

has aliases => (
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    auto_deref => 1,
);

has _aliases_map => (
    is       => 'ro',
    default  => sub {
        my $self = shift;
        return unless $self->aliases;

        my $mapping = {};
        my $num = $self->range_min;
        for my $alias ($self->aliases) {
            $mapping->{$alias} = $num;
            $num++;
        }
        $mapping;
    },
);

no Mouse;

sub BUILD {
    my $self = shift;

    my @expanded;
    my $entity = $self->entity;

    if ($self->aliases) {
        my $reg = '('. join('|', map {quotemeta $_} $self->aliases).')';
        $entity =~ s/$reg/$self->_aliases_map->{lc($1)}/eig;
    }

    for my $item (split /,/, $entity) {
        my ($range_or_num, $increments) = split m!/!, $item, 2;
        if ($increments) {
            die 'entity not valid. (range is strange)' unless $self->_is_range($range_or_num);

            my $count = 0;
            for my $i ($self->_expand_range($range_or_num)) {
                push @expanded, $i if $count % $increments == 0;
                $count++;
            }
        }
        else {
            if ($self->_is_range($range_or_num)) {
                push @expanded, $self->_expand_range($range_or_num);
            }
            else {
                die 'entity not valid. (not a number or strange range)' unless $range_or_num =~ /^[0-9]+$/;
                die 'entity not valid. (too much item)' if $range_or_num > $self->range_max;
                die 'entity not valid. (too less item)' if $range_or_num < $self->range_min;

                push @expanded, $range_or_num;
            }
        }
    }
    if ($self->field eq 'day_of_week') {
        if (grep {$_ == 7} @expanded) {
            push @expanded, 0;
        }
    }
    @expanded = uniq sort {$a <=> $b} @expanded;
    $self->expanded([@expanded]);
}

sub _is_range {
    my ($self, $str) = @_;
    return 1 if $str eq '*';

    my ($from, $to) = split /-/, $str, 2;
    return () unless $to;
    return () unless $from =~ /^[0-9]+$/;
    return () unless $to   =~ /^[0-9]+$/;

    return () if $to   <= $from;
    return () if $to   >  $self->range_max;
    return () if $from <  $self->range_min;

    return 1;
}

sub _expand_range {
    my ($self, $str) = @_;

    my ($from, $to);

    if ($str eq '*') {
        $from = $self->range_min;
        $to   = $self->range_max;
    }
    else {
        ($from, $to) = split /-/, $str, 2;
    }

    ($from..$to);
}

sub stringify {shift->entity}

sub match {
    my ($self, $num) = @_;

    grep {$num == $_} @{ $self->expanded };
}

__PACKAGE__->meta->make_immutable;

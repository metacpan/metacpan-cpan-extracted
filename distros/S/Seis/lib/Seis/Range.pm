package Seis::Range;
use strict;
use warnings;
use utf8;
use 5.010_001;

use overload (
    '@{}' => sub {
        warn "GAH!";
    },
    fallback => 1,
);

sub new {
    my ($class, $start, $end) = @_;
    bless {
        start => $start,
        end   => $end,
    }, $class;
}

sub gist {
    my $self = shift;
    $self->{start} .. $self->{end};
}

1;


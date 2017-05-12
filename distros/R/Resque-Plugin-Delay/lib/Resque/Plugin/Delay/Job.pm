package Resque::Plugin::Delay::Job;
use 5.008001;
use strict;
use warnings;

use Moose::Role;

has start_time  => (
    is       => 'rw',
);

around payload_reader => sub {
    my ($orig, $self, $hr) = @_;

    $orig->($self, $hr);
    $self->start_time( $hr->{start_time} ) if $hr->{start_time};
};

around payload_builder => sub {
    my ($orig, $self) = @_;

    my $payload = $orig->($self);
    $payload->{start_time} = $self->start_time,

    return $payload;
};

1;


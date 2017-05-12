package Resque::Plugin::Retry::Job;
use 5.008001;
use strict;
use warnings;

use Moose::Role;
use Try::Lite;

has max_retry  => (
    is       => 'rw',
    default  => sub { 0 },
);

has retry_count  => (
    is       => 'rw',
    default  => sub { 0 },
);

around payload_reader  => sub {
    my ($orig, $self, $hr) = @_;

    $orig->($self, $hr);
    $self->max_retry( $hr->{max_retry} )     if $hr->{max_retry};
    $self->retry_count( $hr->{retry_count} ) if $hr->{retry_count};
};

around payload_builder => sub {
    my ($orig, $self) = @_;

    my $payload = $orig->($self);
    $payload->{max_retry}   = $self->max_retry;
    $payload->{retry_count} = $self->retry_count;

    return $payload;
};


around perform => sub {
    my ($orig, $self) = @_;

    try {
        $orig->($self);
    }
    '*' => sub {
        my $retry_count = $self->retry_count();
        die $@ if $retry_count >= $self->max_retry;
        $self->retry_count($retry_count + 1);

        # Since want to update payload, do not use Resque::Job#enqueue
        $self->resque->push($self->queue, +{
                %{$self->payload},
                retry_count => $self->retry_count,
            }
        );
    };
};


1;


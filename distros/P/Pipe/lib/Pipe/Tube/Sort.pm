package Pipe::Tube::Sort;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.05';

sub init {
    my ($self, $expr) = @_;
    $self->logger("Receiving the sort expression: '" . (defined $expr ? $expr : '') .  "'");
    $self->{expr} = $expr;
    $self->{data} = [];
    return $self;
}

sub run {
    my ($self, @input) = @_;
    push @{ $self->{data} }, @input;
    return;
}

sub finish {
    my ($self) = @_;

    $self->logger("The sort expression: " . (defined $self->{expr} ? $self->{expr} : ''));

    my $sub = $self->{expr};
	my @sorted;
    if (defined $sub) {
        @sorted = sort { $sub->($a, $b) } @{ $self->{data} };
    } else {
        @sorted = sort @{ $self->{data} };
    }
	return @sorted;
}

1;


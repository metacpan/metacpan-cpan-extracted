package Net::NATS2::Message;

use v5.10;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub subject {
    my $self = shift;
    $self->{subject} = shift if @_;
    return $self->{subject};
}

sub sid {
    my $self = shift;
    $self->{sid} = shift if @_;
    return $self->{sid};
}

sub reply_to {
    my $self = shift;
    $self->{reply_to} = shift if @_;
    return $self->{reply_to};
}

sub length {
    my $self = shift;
    $self->{length} = shift if @_;
    return $self->{length};
}

sub header_length {
    my $self = shift;
    $self->{header_length} = shift if @_;
    return $self->{header_length};
}

sub headers {
    my $self = shift;
    $self->{headers} = shift if @_;
    return $self->{headers};
}

sub data {
    my $self = shift;
    $self->{data} = shift if @_;
    return $self->{data};
}

sub subscription {
    my $self = shift;
    $self->{subscription} = shift if @_;
    return $self->{subscription};
}

1;

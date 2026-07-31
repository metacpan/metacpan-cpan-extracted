package Net::NATS2::Subscription;

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

sub group {
    my $self = shift;
    $self->{group} = shift if @_;
    return $self->{group};
}

sub sid {
    my $self = shift;
    $self->{sid} = shift if @_;
    return $self->{sid};
}

sub callback {
    my $self = shift;
    $self->{callback} = shift if @_;
    return $self->{callback};
}

sub client {
    my $self = shift;
    $self->{client} = shift if @_;
    return $self->{client};
}

sub message_count : lvalue { $_[0]->{message_count} }
sub max_msgs      : lvalue { $_[0]->{max_msgs} }

sub defined_max {
    return defined $_[0]->{max_msgs};
}

sub auto_unsubscribe {
    my $self = shift;
    my ($max_msgs) = @_;
    $self->client->unsubscribe($self, $max_msgs);
    return $self;
}

sub unsubscribe {
    my $self = shift;
    $self->client->unsubscribe($self);
    return $self;
}

1;

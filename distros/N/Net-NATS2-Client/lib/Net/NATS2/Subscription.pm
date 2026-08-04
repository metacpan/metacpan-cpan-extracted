package Net::NATS2::Subscription;

use v5.10;
use strict;
use warnings;

use Net::NATS2::Base;

has message_count => 0;
has $_ for qw(subject group sid callback client max_msgs);

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

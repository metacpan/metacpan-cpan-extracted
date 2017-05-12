package Net::PulseMeter::Sensor::Timelined::HashedIndicator;
use strict;
use warnings 'all';

use base qw/Net::PulseMeter::Sensor::Timeline/;

sub aggregate_event {
    my ($self, $key, $data) = @_;
    $self->r->hset($key, $_, $data->{$_}) for (keys(%$data));
}

1;

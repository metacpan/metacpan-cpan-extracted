package Net::PulseMeter::Sensor::Timelined::Indicator;
use strict;
use warnings 'all';

use base qw/Net::PulseMeter::Sensor::Timeline/;

sub aggregate_event {
    my ($self, $key, $value) = @_;
    $self->r->set($key, $value);
}

1;

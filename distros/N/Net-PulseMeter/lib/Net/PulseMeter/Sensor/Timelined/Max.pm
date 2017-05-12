package Net::PulseMeter::Sensor::Timelined::Max;
use strict;
use warnings 'all';
use Data::Uniqid qw/uniqid/;

use base qw/Net::PulseMeter::Sensor::Timeline/;

sub aggregate_event {
    my ($self, $key, $value) = @_;
    $self->r->zadd(
        $key,
        $value,
        sprintf("%s::%s", $value, uniqid())
    );
    $self->r->zremrangebyrank($key, 0, -2);
}

1;

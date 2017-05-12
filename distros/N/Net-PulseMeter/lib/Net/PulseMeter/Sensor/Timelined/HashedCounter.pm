package Net::PulseMeter::Sensor::Timelined::HashedCounter;
use strict;
use warnings 'all';

use base qw/Net::PulseMeter::Sensor::Timeline/;

sub aggregate_event {
    my ($self, $key, $data) = @_;
    for (keys(%$data)) {
        $self->r->hincrby($key, $_, $data->{$_}); 
        $self->r->hincrby($key, "total", $data->{$_}); 
    }
}

1;

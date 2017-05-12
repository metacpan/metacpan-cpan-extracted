package Net::PulseMeter::Sensor::HashedCounter;
use strict;
use warnings 'all';

use base qw/Net::PulseMeter::Sensor::Counter/;

sub event {
    my ($self, $data) = @_;
    for (keys %$data) {
        $self->r->hincrby($self->value_key, $_, $data->{$_});
        $self->r->hincrby($self->value_key, "total", $data->{$_});
    }
}

1;

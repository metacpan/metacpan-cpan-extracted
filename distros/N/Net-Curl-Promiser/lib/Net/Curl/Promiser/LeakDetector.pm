package Net::Curl::Promiser::LeakDetector;

use strict;
use warnings;

sub DESTROY {
    my ($self) = @_;

    if (!$self->{'ignore_leaks'} && ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT' ) {
        warn "$self: destroyed at global destruction; memory leak likely!";
    }
}

1;

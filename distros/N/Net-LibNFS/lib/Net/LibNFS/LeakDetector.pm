package Net::LibNFS::LeakDetector;

use strict;
use warnings;

sub DESTROY {
    my ($self) = @_;

    if ($$ == $self->{'pid'} && ${^GLOBAL_PHASE} && (${^GLOBAL_PHASE} eq 'DESTRUCT')) {
        warn("$self: DESTROY at global destruction; memory leak likely!\n");
    }

    return;
}

1;

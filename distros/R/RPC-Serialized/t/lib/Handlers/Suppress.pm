package Handlers::Suppress;

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Handler';

sub invoke {
    my $self = shift;
    return scalar @_;
}

1;

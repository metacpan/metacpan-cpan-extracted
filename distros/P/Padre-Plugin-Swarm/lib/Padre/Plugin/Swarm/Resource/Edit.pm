package Padre::Plugin::Swarm::Resource::Edit;
use strict;
use warnings;

use Class::XSAccessor
        constructor => 'new',
        accessors => [qw(
                resource
                operation
                position
                body
                delta_time
                sequence
                )];

1;

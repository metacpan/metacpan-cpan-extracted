package TaskPipe::Sample_Test;

use Moose;
extends 'TaskPipe::Sample';

has schema_templates => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'Project',
    'Project_Test'
]});

1;

package TaskPipe::Task_Sleep;

use Moose;
use Data::Dumper;
extends 'TaskPipe::Task';
with 'MooseX::ConfigCascade';


sub action{
    my ($self) = @_;
    while(1){ sleep 1 }
}

1;

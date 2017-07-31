package Pask::Command;

use Carp;

use Pask::Container;

sub add {
    my ($name, $command) = @_;
    Carp::confess "command need a task name!" unless $name;
    Carp::confess "command can not be null!" unless $command;
    Pask::Container::set_command $name, $command;
}

1;

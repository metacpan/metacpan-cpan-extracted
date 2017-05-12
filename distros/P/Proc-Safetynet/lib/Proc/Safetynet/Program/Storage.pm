package Proc::Safetynet::Program::Storage;
use strict;
use warnings;
use Carp;

use Moose;

# abstract class

sub retrieve_all {
    croak "unimplemented";
}

sub retrieve {
    croak "unimplemented";
}

sub add {
    croak "unimplemented";
}

sub remove {
    croak "unimplemented";
}

sub commit {
    croak "unimplemented";
}

sub reload {
    croak "unimplemented";
}

1;

__END__

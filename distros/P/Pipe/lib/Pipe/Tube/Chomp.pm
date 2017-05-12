package Pipe::Tube::Chomp;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.05';

sub run {
    my ($self, @input) = @_;
    chomp @input;
    return @input;
}

1;


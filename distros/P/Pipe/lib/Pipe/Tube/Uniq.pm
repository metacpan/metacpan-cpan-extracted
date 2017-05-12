package Pipe::Tube::Uniq;
use strict;
use warnings;
use 5.006;

use base 'Pipe::Tube';

our $VERSION = '0.05';

sub run {
    my ($self, @input) = @_;

    my @result;
    foreach my $v (@input) {
        next if defined $self->{last} and $self->{last} eq $v;

        $self->{last} = $v;
        push @result, $v;
    }
    return @result;
}


1;




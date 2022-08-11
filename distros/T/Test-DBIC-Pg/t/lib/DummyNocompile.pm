package DummyNocompile;
use warnings;
use strict;

sub connect {
    my $class = shift;
    return bless [@_], $class;
}

sub deploy {
    my $self = shift;
}

#1;

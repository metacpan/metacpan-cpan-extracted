package DummyNoconnect;
use warnings;
use strict;

sub connect {
    my $class = shift;
    die "No connect\n";
}

sub deploy {
    my $self = shift;
}

1;


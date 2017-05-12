package Seis::Duration;
use strict;
use warnings;
use utf8;
use 5.018_000;
use parent qw(Seis::Real);

sub _new {
    my ($class, $x) = @_;
    bless \$x, $class;
}

1;


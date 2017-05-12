package Seis::Complex;
use strict;
use warnings;
use utf8;
use 5.010_001;

# DO NOT CALL THIS DIRECTLY
sub _new {
    my ($class, $stuff) = @_;
    bless \$stuff, $class;
}

1;


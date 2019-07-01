use strict;
use warnings;

my @needs = qw(milk butter bread);

my @main_list = (
    \@needs
    [qw(without a need of a variable)],
    ['!', '$', '%', '&', '*'],
);

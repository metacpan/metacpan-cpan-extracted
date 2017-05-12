use strict;
use warnings;
use Data::Dumper qw(Dumper);

my $bundle = ['#bundle', 0.1];

push @$bundle, ['/destination', 'i', 42, 'i', 43];
push @$bundle, ['/destination2', 'f', 0.1];

print Dumper($bundle);

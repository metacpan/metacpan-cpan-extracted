#!/usr/bin/perl 

use strict;
use warnings;

use Pod::Knit;

my $knit = Pod::Knit->new(
    config_file => 'knit.yml',
    source_file => 'sample.pod',
);

print $knit->as_pod;


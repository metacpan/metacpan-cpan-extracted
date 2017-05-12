#!/usr/bin/perl -T

use strict;
use warnings;

use Search::Tools;
use Data::Dump qw/pp/;

for my $q (@ARGV) {
    my $query = Search::Tools->parser->parse($q);

    for my $term ( @{ $query->terms } ) {
        print "$q -> $term\n";
    }
}

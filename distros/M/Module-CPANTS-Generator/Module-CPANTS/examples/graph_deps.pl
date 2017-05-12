#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use GraphViz;
use Module::CPANTS;

my $graph = new GraphViz;
my $cpants = Module::CPANTS->new->data;

for my $from (keys %$cpants) {
  for my $to (@{ $cpants->{ $from }->{ requires } }) {
    $graph->add_edge( $from, $to );
  }
}

#$graph->as_png("cpan.png");
print $graph->_as_debug;

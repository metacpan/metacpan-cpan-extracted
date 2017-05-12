#!/usr/local/bin/perl
use strict;
use warnings;
use lib ("lib");
use Queue::Q4M::Benchmark;

main() unless caller();

sub main {
    my $app = Queue::Q4M::Benchmark->new_with_options();
    $app->run;
}

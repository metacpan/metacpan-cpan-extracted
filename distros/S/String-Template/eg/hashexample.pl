#!/usr/bin/env perl

use strict;
use warnings; 
use String::Template qw(expand_hash);
use Data::Dumper;

my $hash =
{
    X => 1,
    Y => '<X>',
    Z => '<Y>',
    Q => '<X><Y><Z>'
};

if (expand_hash($hash, 2))
{
    print "All expanded\n";
}
else
{
    print "something missing\n";
}

print Dumper($hash);

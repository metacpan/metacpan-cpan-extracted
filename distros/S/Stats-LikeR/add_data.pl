#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

my $data = { 'Jack Smith' => { age => 30 } };
my $n = { 
    'Jack Smith' => { dept => 'Engineering' },             # Update existing (Hash)
    'Jane Doe'   => { age => 25, dept => 'Sales' },        # Add new (Hash)
    'Bob Brown'  => [ 'age', 40, 'dept', 'IT' ],           # Add new (Array)
    'Invalid'    => 'Not a reference'                      # Edge case safety
};
add_data($data, $n); # will add data to 'Jack Smith', as well as new keys for Jane and Bob.
p $data;

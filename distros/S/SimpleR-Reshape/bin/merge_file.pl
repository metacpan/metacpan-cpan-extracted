#!/usr/bin/perl
use strict;
use warnings;

use SimpleR::Reshape;
use Getopt::Std;

my %opt;
getopt( 'fkvFKVo', \%opt );

$opt{o} //= "$opt{F}.merge";

for my $k ( qw/k K/ ) {                #key
  $opt{$k} = defined $opt{$k} ? [ map { int } split /,/, $opt{$k} ] : [0];
}

for my $k ( qw/v V/ ) {                #value
  $opt{$k} = [ map { int } split /,/, $opt{$k} ] if ( exists $opt{$k} );
}

merge_file(
  $opt{f},                             #small_file
  $opt{F},                             #big_file, left join, small_file
  default_cell_value => '',
  merge_file         => $opt{o},
  value_x            => $opt{v},
  value_y            => $opt{V},
  by_x               => $opt{k},
  by_y               => $opt{K},
);

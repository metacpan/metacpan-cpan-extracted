#!/usr/bin/perl -w
use strict;

use Test::More tests => 1;
use Pipe;


my @rows = <DATA>;
chomp @rows;
{
  my @resp = Pipe->for(@rows)->csv->run;
  is_deeply \@resp, [ 
                      ["one", "two", "three"], 
                      ["few", "many, more", "uncountable"],
                    ], "2 rows of csv file";
}




__DATA__
one,two,three
few,"many, more",uncountable

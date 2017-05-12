#!/usr/bin/perl

use strict; use warnings;
use Test::More;
use FindBin '$Bin';

use lib "$Bin/lib";
use Row::Test;

# example of parsing a whole table

my @rows = map {
              Row::Test->parse($_) 
           }
           <DATA>;

my @long = grep {
               $_->duration->in_units('minutes') > 121
           } @rows;

is_deeply [ map $_->last, @long ],
          [ 'Stone ', 'Clown ' ],
          "Correct data";

done_testing;

__DATA__
Fred J Bloggs | 2009-12-17 | 01:00
Fred F Stone  | 2009-12-17 | 04:00
Mary J Blige  | 2009-12-17 | 02:00
Coco T Clown  | 2009-12-17 | 03:00

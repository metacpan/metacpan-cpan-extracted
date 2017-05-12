#!/usr/bin/perl -w

use strict;
use warnings; 
use Test::More tests => 1;
 
BEGIN {
    use_ok('Parse::PAUSE');
}
 
diag("Testing Parse::PAUSE $Parse::PAUSE::VERSION");

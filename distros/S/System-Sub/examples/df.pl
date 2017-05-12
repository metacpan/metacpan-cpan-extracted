#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

use lib '../lib';
use System::Sub df => [ '%ENV' => { POSIXLY_CORRECT => 1 } ];

df sub {
    return if $. == 1;
    printf "%s: %s\n", (split / +/, $_[0])[5, 4];
    #my @line = split / +/, $_[0];
    #print "$line[5]: $line[4]\n";
};


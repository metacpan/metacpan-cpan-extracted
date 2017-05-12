#!/usr/bin/env perl 

use strict;
use warnings;
BEGIN {
    push @INC, ('blib/lib', 'blib/arch');
}
use lib '../lib';
use blib;

use Parse::STDF;
use Test::More tests => 1;
note 'Testing Parse::STDF->new()';

my $s = Parse::STDF->new("data/test.stdf"); 
ok ( defined ($s), 'opened data/test.stdf');

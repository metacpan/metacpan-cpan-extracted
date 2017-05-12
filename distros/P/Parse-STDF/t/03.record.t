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
note 'Testing Parse::STDF->get_record()';

my $s = Parse::STDF->new("data/test.stdf"); 

my $rec_count = 0;
while ( $s->get_record() ) { $rec_count++; }
ok ( $rec_count == 22, 'read 22 records from data/test.stdf');

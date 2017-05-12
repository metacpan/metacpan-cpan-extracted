#!/usr/bin/env perl 

use strict;
use warnings;
BEGIN {
    push @INC, ('blib/lib', 'blib/arch');
}
use lib '../lib';
use blib;

use Parse::STDF;
use Test::More tests => 22;
note 'Testing Parse::STDF->recname()';

my $s = Parse::STDF->new("data/test.stdf"); 

my %rec_names = 
( 
"MIR" => 0,
"SDR" => 0,
"PCR" => 0,
"MRR" => 0,
"WIR" => 0,
"PIR" => 0,
"DTR" => 0,
"ATR" => 0,
"HBR" => 0,
"SBR" => 0,
"PMR" => 0,
"PGR" => 0,
"PLR" => 0,
"RDR" => 0,
"WRR" => 0,
"WCR" => 0,
"TSR" => 0,
"MPR" => 0,
"FTR" => 0,
"BPS" => 0,
"EPS" => 0
);

while ( $s->get_record() ) { $rec_names{$s->recname()}++; }

foreach my $name ( keys %rec_names ) { ok ( $rec_names{$name} > 0, "check record: $name" ); }

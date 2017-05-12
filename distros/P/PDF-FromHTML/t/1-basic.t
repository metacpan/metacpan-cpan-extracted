#!/usr/bin/perl
use strict;
print "1..2\n";

require PDF::FromHTML;
print "ok 1 # loading the module\n";

my $pdf = PDF::FromHTML->new;
$pdf->can('load_file') or print "not ";
print "ok 2 # basic API sanity\n";

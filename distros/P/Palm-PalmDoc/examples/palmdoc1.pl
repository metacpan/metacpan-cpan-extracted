#!/usr/bin/perl

use strict;
use Palm::PalmDoc;

my $doc = Palm::PalmDoc->new({INFILE=>"foo.txt",OUTFILE=>"foo.pdb",TITLE=>"foo bar"});
$doc->read_text();
$doc->write_text();

#!/usr/bin/perl

use strict;
use Palm::PalmDoc;

my $doc = Palm::PalmDoc->new(INFILE=>"README");
$doc->compression(1); #Compression is off by default
$doc->read_text();
open(F,">readme.pdb") || die $!;
print F $doc->pdb_header,$doc->body;
close(F);
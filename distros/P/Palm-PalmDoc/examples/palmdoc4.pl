#!/usr/bin/perl

use strict;
use Palm::PalmDoc;

my $doc = Palm::PalmDoc->new();
$doc->parse_from_file("README");
open(F,">readme.pdb") || die $!;
$doc->parse_from_filehandle("",\*F);
$doc->compression(1); #Compression is off by default
$doc->read_text();
$doc->write_text();

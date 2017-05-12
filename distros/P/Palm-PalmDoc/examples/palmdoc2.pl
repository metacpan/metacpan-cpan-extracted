#!/usr/bin/perl

use strict;
use Palm::PalmDoc;

my $doc = Palm::PalmDoc->new({OUTFILE=>"foo2.pdb",TITLE=>"foo bar"});
$doc->body("Foo Bar"x100);
$doc->write_text();

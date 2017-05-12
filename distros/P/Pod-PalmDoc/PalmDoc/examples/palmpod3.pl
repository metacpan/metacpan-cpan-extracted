#!/usr/bin/perl

use strict;
use Pod::PalmDoc;

my $parser = Pod::PalmDoc->new();
$parser->compress(1);
$parser->title("POD Foo");
open(FOO,"<Pod/PalmDoc.pm") || die $!;
open(BAR,">foo.pdb") || die $!;
$parser->parse_from_filehandle(\*FOO, \*BAR); 
close(FOO);
close(BAR);

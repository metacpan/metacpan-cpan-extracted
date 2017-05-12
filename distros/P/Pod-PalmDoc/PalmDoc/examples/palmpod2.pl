#!/usr/bin/perl

use strict;
use Pod::PalmDoc;

my $parser = Pod::PalmDoc->new();
$parser->compress(1);
$parser->title("POD Foo");
open(FOO,">foo.pdb") || die $!;
$parser->parse_from_filehandle(\*STDIN, \*FOO); 
close(FOO);
# Read from command line or default value

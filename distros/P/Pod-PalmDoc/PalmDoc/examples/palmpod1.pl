#!/usr/bin/perl

use strict;
use Pod::PalmDoc;

my $parser = Pod::PalmDoc->new();
$parser->compress(1);
$parser->title("POD Foo");
$parser->parse_from_file($ARGV[0] || "Pod/PalmDoc.pm", "foo.pdb"); 
# Read from command line or default value

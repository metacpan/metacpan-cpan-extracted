#!/usr/bin/perl

use warnings;
use strict;
use XML::Simple;
use Data::Dumper;
$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

my $filename = shift
   or die "please specify a filename\n";


print Dumper( XMLin($filename) );


#!/usr/bin/perl 
use strict;
use warnings;
use Parse::WBXML;
use File::Slurp qw(read_file);

my $file = shift @ARGV;
die "File not found" unless -f $file;

my $wbxml = Parse::WBXML->new;
print $wbxml->dump_from_buffer(read_file $file), "\n";


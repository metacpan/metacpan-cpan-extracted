#!/usr/bin/perl -w

use strict;

BEGIN { $| = 1; print "1..6\n"; }
END { print "not ok 1\n" unless $::loaded_dvi_parse; }

my $dir = ( -d 't' ? 't' : '.' );

use TeX::DVI::Parse;
$::loaded_dvi_parse = 1;
print "ok 1\n";

print qq!Do new TeX::DVI::Print("$dir/parse.dvi")\n!;
my $dvi_parse = new TeX::DVI::Print("$dir/parse.dvi") or print 'not ';
print "ok 2\n";

print "Parse the file\n";
open OUT, "> $dir/parse.out" or do { print "not ok 3\n"; exit(); };
select OUT;
$dvi_parse->parse();
close OUT;
select STDOUT;

print "ok 3\n";

$/ = undef;

print "Read the output back\n";
open FILE, "$dir/parse.out" or do
	{ print "not ok 4\n"; exit; };
print "ok 4\n";
my $out = <FILE>;
close FILE;

print "Read the correct output\n";
open FILE, "$dir/parse.txt" or do
	{ print "not ok 5\n"; exit; };
print "ok 5\n";
my $orig = <FILE>;
close FILE;

print "Compare them\n";

print "Expected\n$orig\nGot\n$out\nnot " if $orig ne $out;
print "ok 6\n";

#!/usr/bin/perl -w

use strict;

BEGIN { $| = 1; print "1..6\n"; }
END { print "not ok 1\n" unless $::loaded_dvi; }

my $dir = ( -d 't' ? 't' : '.' );

use TeX::DVI;
$::loaded_dvi = 1;
print "ok 1\n";

unlink "$dir/texput1.out" if -f "$dir/texput1.out";
print qq!Do new TeX::DVI "$dir/texput1.out"\n!;
my $dvi = new TeX::DVI "$dir/texput1.out" or
	do { print "not ok 2\n"; exit; };
print "ok 2\n";

print "Fill write the DVI\n";
$dvi->preamble();
$dvi->begin_page();
$dvi->push();
$dvi->black_box(1000000, 200000);
$dvi->hskip(2000000);
$dvi->black_box(500000, 1200000);
$dvi->pop();
$dvi->end_page();
$dvi->postamble();
$dvi->close();

print "ok 3\n";

$/ = undef;

print "Read the output back\n";
open FILE, "$dir/texput1.out" or do
	{ print "not ok 4\n"; exit; };
print "ok 4\n";
my $out = <FILE>;
close FILE;

$out =~ s!output.*GMT!output 19/08/98 15:52:01 GMT!;

print "Read the correct output\n";
open FILE, "$dir/texput1.dvi" or do
	{ print "not ok 5\n"; exit; };
print "ok 5\n";
my $orig = <FILE>;
close FILE;

print "Compare them\n";

print qq!Expected\n@{[ map { sprintf "%o", ord $_ } split //, $orig ]}\nGot\n@{[ map { sprintf "%o", ord $_ } split //, $out ]}\nnot ! if $out ne $orig;
print "ok 6\n";

#!/usr/bin/perl -w

use strict;
use vars qw! $font $dir !;

BEGIN {
$| = 1;
eval ' use Font::TFM; ';
if ($@)
	{ print "1..0\n"; exit; }

$dir = ( -d 't' ? 't' : '.' );
$Font::TFM::TEXFONTSDIR = $dir;

$font = new_at Font::TFM "cmr10", 12
	or do { print "1..0\n"; exit; }
}

print "1..6\n";

use TeX::DVI;
print "ok 1\n";

unlink "$dir/texput2.out" if -f "$dir/texput2.out";
print qq!Do new TeX::DVI "$dir/texput2.out"\n!;
my $dvi = new TeX::DVI "$dir/texput2.out" or
	do { print "not ok 2\n"; exit; };
print "ok 2\n";

$dvi->preamble();
$dvi->begin_page();
$dvi->push();
my $fn = $dvi->font_def($font);
$dvi->font($fn);
$dvi->word("difficulty");
$dvi->hskip($font->space());
$dvi->word("AVA");
$dvi->black_box($font->em_width(), $font->x_height());
$dvi->pop();
$dvi->end_page();
$dvi->postamble();
$dvi->close();

print "ok 3\n";

$/ = undef;

print "Read the output back\n";
open FILE, "$dir/texput2.out" or do
	{ print "not ok 4\n"; exit; };
print "ok 4\n";
my $out = <FILE>;
close FILE;

$out =~ s!output.*GMT!output 19/08/98 15:52:02 GMT!;

print "Read the correct output\n";
open FILE, "$dir/texput2.dvi" or do
	{ print "not ok 5\n"; exit; };
print "ok 5\n";
my $orig = <FILE>;
close FILE;

print "Compare them\n";

print qq!Expected\n@{[ map { sprintf "%o", ord $_ } split //, $orig ]}\nGot\n@{[ map { sprintf "%o", ord $_ } split //, $out ]}\nnot ! if $out ne $orig;
print "ok 6\n";

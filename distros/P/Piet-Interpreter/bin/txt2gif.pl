#!/usr/local/bin/perl -w
#
#  Piet utility - converts human-readable text files to images
#

use strict;
use Image::Magick;
use Getopt::Std;

getopts('s:o:');
our($opt_s, $opt_o);
my $codel_size = $opt_s || 1;   #  not yet (todo)
my $outfile    = $opt_o || die "must specify output file";

my $infile = shift || die "must specify text file";
open(IN,$infile)   || die "can't open text file: $!";

my @txtarr;
my $rows = 0;
my $cols = 0;

my %a2hex = (  'lR' => 'FFC0C0',  'lY' => 'FFFFC0',  'lG' => 'C0FFC0',
	       'lC' => 'C0FFFF',  'lB' => 'C0C0FF',  'lM' => 'FFC0FF',
	       'R'  => 'FF0000',  'Y'  => 'FFFF00',  'G'  => '00FF00',
	       'C'  => '00FFFF',  'B'  => '0000FF',  'M'  => 'FF00FF',
	       'dR' => 'C00000',  'dY' => 'C0C000',  'dG' => '00C000',
	       'dC' => '00C0C0',  'dB' => '0000C0',  'dM' => 'C000C0',
	       'Wt' => 'FFFFFF',  'Bk' => '000000',
	       );


while(<IN>) {
    s/\s*\#.*$//;       #  strip comments and skip blank lines
    next if /^\s*$/;
    my @tmp = split;
    push(@txtarr,\@tmp);
    $rows++;
    $cols = ($cols>@tmp)?$cols:@tmp;
}

$cols *= $codel_size;
$rows *= $codel_size;

print "Converting $infile:  ($cols x $rows)\n";
my $img = Image::Magick->new;
$img->Set(size=>"$cols"."x$rows");    
$img->ReadImage('xc:white');

my $j = 0;
for my $arref (@txtarr) {
    my $i = 0;
    for my $cabbr (@$arref) {

	#  $img->Draw doesn't seem to work - why?

	for my $m (0..($codel_size-1)) {
	    for my $n (0..($codel_size-1)) {
		my $color = Hex2Color($a2hex{$cabbr});
		my $x = ($i*$codel_size) + $m;
		my $y = ($j*$codel_size) + $n;

		$img->Set("pixel[$x,$y]"=>$color);
	    }
	}

	$i++;
    }
    $j++;
}

$img->WriteImage($outfile);

###

sub Hex2Color {
    my $hex = uc(shift);
    my @nums = $hex =~ /^([0-9A-F]{2})([0-9A-F]{2})([0-9A-F]{2})$/;
    return join(",",(map {257*hex($_)} ($1,$2,$3)),0);
}


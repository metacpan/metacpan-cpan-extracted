#!/usr/local/bin/perl -w
#
#  Piet utility - converts images to human-readable text files
#

use strict;
use Image::Magick;
use Getopt::Std;

getopts('s:');
our($opt_s);
my $codel_size = $opt_s || 1;

my $infile = shift || die "must specify image file";
die "can't find file $infile" unless (-f $infile);

my $img    = Image::Magick->new;
$img->Read(filename=>$infile);

my $cols = $img->Get('columns');
my $rows = $img->Get('rows');
print "#  Image $infile: ($cols x $rows)\n";


my %hex2a  = ( 'FFC0C0' => 'lR', 'FFFFC0' => 'lY', 'C0FFC0' => 'lG',
	       'C0FFFF' => 'lC', 'C0C0FF' => 'lB', 'FFC0FF' => 'lM',
	       'FF0000' => ' R', 'FFFF00' => ' Y', '00FF00' => ' G',
	       '00FFFF' => ' C', '0000FF' => ' B', 'FF00FF' => ' M',
	       'C00000' => 'dR', 'C0C000' => 'dY', '00C000' => 'dG',
	       '00C0C0' => 'dC', '0000C0' => 'dB', 'C000C0' => 'dM',
	       'FFFFFF' => 'Wt', '000000' => 'Bk',
	       );

my $j = 0;
while ($j<=($rows-1)) {
    my $i = 0;
    while ($i<=($cols-1)) {
	my $color = $img->Get("pixel[$i,$j]");
	my $hexcolor = HexColor($color);
	print "$hex2a{$hexcolor} ";
	$i += $codel_size;
    }
    print "\n";
    $j += $codel_size;
}

###

sub HexColor {
    my ($number, $hex);
    (shift @_) =~ /^(\d+),(\d+),(\d+)/;
    for $number ($1,$2,$3) {
	$hex .= sprintf("%02X", $number/257);
    }
    return $hex;
}

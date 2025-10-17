#!/usr/bin/perl
use strict;
use warnings;

use lib qw(lib);

use SVG::Barcode::UPCA;

my $obj = SVG::Barcode::UPCA->new;

my $svg_black = $obj->plot('012345678905');

$obj->foreground('red');
$obj->textsize(0);
$obj->lineheight(20);

my $svg_red = $obj->plot('012345678905');

open(FILE, '>', '012345678905_black_text.svg');
print FILE $svg_black;
close(FILE);

open(FILE, '>', '012345678905_red_notext.svg');
print FILE $svg_red;
close(FILE);



# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;
my $code;

# OO interface
my $sheet = OCBNET::CSS3->new;
my $outer = OCBNET::CSS3->new;
my $inner = OCBNET::CSS3->new;

$outer->set('outer');
$outer->bracket = '{';
$outer->suffix = ';';
$inner->set('inner');
$inner->bracket = '{';

$sheet->add($outer);
$outer->add($inner);

my $clone_flat = $sheet->clone(0);
my $clone_deep = $sheet->clone(1);

is ($sheet->render,      'outer{inner{}};', 'original renders correctly');
is ($clone_flat->render, '',                'flat clone renders correctly');
is ($clone_deep->render, 'outer{inner{}};', 'deep clone renders correctly');


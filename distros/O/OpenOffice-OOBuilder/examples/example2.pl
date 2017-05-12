#!/usr/bin/perl

use strict;
use warnings;
use OpenOffice::OOCBuilder;

my @figures=(12.25,9.66,9.43,2.67,15.96,45.68,75.32,0.56,65.81);

# - start sxc document
my $sheet=new OpenOffice::OOCBuilder();

# - set title column B
$sheet->set_bold (1);
$sheet->set_align('right');
$sheet->set_fontsize(12);
$sheet->set_data_xy ('B', 1, 'VALUES');

# - reset style
$sheet->set_bold (0);
$sheet->set_align('left');
$sheet->set_fontsize(10);

$sheet->goto_xy ('B',2);
$sheet->set_auto_xy (0,1);   # go 1 row down after each data input

my ($cell1, $cell2);
$cell1=$sheet->get_cell_id;  # we'll need this to create a formula

foreach $_ (@figures) {
  $sheet->set_data ($_, 'float');
}
$cell2=$sheet->get_cell_id;
$sheet->cell_update;      # following auto_xy : go 1 row down 
                          #  now without data input

$sheet->set_txtcolor('blue');
$sheet->set_bgcolor('ffff00');
$sheet->set_bold(1);
$sheet->set_data ("=SUM($cell1:$cell2)", 'formula');
$sheet->generate ('example2');
print "example2.sxc generated\n";
exit;

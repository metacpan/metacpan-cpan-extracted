#!/usr/bin/perl

use strict;
use warnings;
use OpenOffice::OOCBuilder;

# - start sxc document
my $sheet=new OpenOffice::OOCBuilder();

# - Set Meta.xml data
$sheet->set_title ('Test document for OOCBuilder');
$sheet->set_author ('Stefan Loones');
$sheet->set_subject ('Document to show methods from OOCBuilder & parent class OOBuilder');
$sheet->set_comments ('Fill in your comments here');
$sheet->set_keywords ('openoffice autogeneration', 'OpenOffice::OOBuilder');
$sheet->push_keywords ('OpenOffice::OOCBuilder');
$sheet->set_meta (1, 'name 1', 'value 1');

# - Set name of first sheet
$sheet->set_sheet_name ('MySheet_1',1);
# - Set some data
# columns can be in numbers or letters
$sheet->set_data_xy (1, 1, 'cell A1');
$sheet->set_data_xy ('C', 2, 'cell C2');
$sheet->goto_cell ('F8');
$sheet->set_data ('cell F8');

# numerique values
$sheet->set_data_xy ('D', 1, 12.25, 'float');
$sheet->set_data_xy ('D', 2, 9.13, 'float');

# formula and style blue & bold
$sheet->set_bold (1);
$sheet->set_txtcolor('blue');
$sheet->set_data_xy ('D', 3, '=SUM(D1:D2)', 'formula');

# - reset style
$sheet->set_bold (0);
$sheet->set_txtcolor('black');

# - go down 5 rows
$sheet->move_cell ('down', 5);
$sheet->set_data ('5 rows down');

# - add another sheet, select it, name it, and put data in it
$sheet->add_sheet;
$sheet->goto_sheet (2);
$sheet->set_sheet_name ('MySheet_2');
$sheet->set_italic (1);
$sheet->set_data_xy (1, 1, 'sheet 2 cell A1');
$sheet->set_italic (0);

$sheet->generate ('example1');
print "example1.sxc generated\n";
exit;

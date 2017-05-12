#!/usr/bin/perl -w

###############################################################################
#
# This example demonstrates writing cell comments. A cell comment is indicated
# in Excel by a small red triangle in the upper right-hand corner of the cell.
#
# reverse('©'), April 2005, John McNamara, jmcnamara@cpan.org
#

use strict;
use Spreadsheet::WriteExcelXML;

my $workbook  = Spreadsheet::WriteExcelXML->new("comments.xls");
my $worksheet = $workbook->add_worksheet();

$worksheet->write        ('B2', 'Hello');
$worksheet->write_comment('B2', 'This is a comment.');

my $str =   '<Font html:Face="Tahoma" html:Size="8">Some </Font><B>'   .
            '<Font html:Face="Tahoma" html:Size="8">bold</Font></B>'   .
            '<Font html:Face="Tahoma" html:Size="8"> and </Font><I>'   .
            '<Font html:Face="Tahoma" html:Size="8">italic</Font></I>' .
            '<Font html:Face="Tahoma" html:Size="8"> text</Font>';

$worksheet->write        ('B4', 'Formatted');
$worksheet->write_comment('B4', $str);

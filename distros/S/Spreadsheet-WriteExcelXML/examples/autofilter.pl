#!/usr/bin/perl -w

#######################################################################
#
# Example of how to create autofilters with Spreadsheet::WriteExcelXML.
#
# reverse('©'), April 2004, John McNamara, jmcnamara@cpan.org
#

use strict;
use Spreadsheet::WriteExcelXML;

my $workbook   = Spreadsheet::WriteExcelXML->new("autofilter.xls");

die "Couldn't create new Excel file: $!.\n" unless defined $workbook;

my $worksheet1 = $workbook->add_worksheet();
my $worksheet2 = $workbook->add_worksheet();
my $worksheet3 = $workbook->add_worksheet();
my $worksheet4 = $workbook->add_worksheet();

my $bold       = $workbook->add_format(bold => 1);


# Extract the data embedded at the end of this file.
my @data;
push @data, [split] while <DATA>;


# Set up several sheets with the same data.
for my $worksheet ($workbook->sheets()) {
    $worksheet->set_column('A:D', 12);
    $worksheet->set_row(0, 20, $bold);
    $worksheet->write('A1', [[@data]]);
}


###############################################################################
#
# Example 1. Autofilter without conditions.
#

$worksheet1->autofilter('A1:D51');


###############################################################################
#
#
# Example 2. Autofilter with a filter condition in the first column.
#

# The range in this example is the same as above but in row-column notation.
$worksheet2->autofilter(0, 0, 50, 3);

# Row, col notation also used here.
$worksheet2->filter_column(0, 'x eq East');


###############################################################################
#
#
# Example 3. Autofilter with a dual filter condition in one of the columns.
#

$worksheet3->autofilter('A1:D51');

# The placeholder "Region" in the filter is ignored and can be any string
# that adds clarity to the expression.
#
$worksheet3->filter_column('A', 'Region eq East or Region eq South');


###############################################################################
#
#
# Example 4. Autofilter with filter conditions in two columns.
#

$worksheet4->autofilter('A1:D51');

$worksheet4->filter_column('A', 'x eq East');
$worksheet4->filter_column('C', 'x > 3000 and x < 8000' );


__DATA__
Region    Item      Volume    Month
East      Apple     9000      July
East      Apple     5000      July
South     Orange    9000      September
North     Apple     2000      November
West      Apple     9000      November
South     Pear      7000      October
North     Pear      9000      August
West      Orange    1000      December
West      Grape     1000      November
South     Pear      10000     April
West      Grape     6000      January
South     Orange    3000      May
North     Apple     3000      December
South     Apple     7000      February
West      Grape     1000      December
East      Grape     8000      February
South     Grape     10000     June
West      Pear      7000      December
South     Apple     2000      October
East      Grape     7000      December
North     Grape     6000      April
East      Pear      8000      February
North     Apple     7000      August
North     Orange    7000      July
North     Apple     6000      June
South     Grape     8000      September
West      Apple     3000      October
South     Orange    10000     November
West      Grape     4000      July
North     Orange    5000      August
East      Orange    1000      November
East      Orange    4000      October
North     Grape     5000      August
East      Apple     1000      December
South     Apple     10000     March
East      Grape     7000      October
West      Grape     1000      September
East      Grape     10000     October
South     Orange    8000      March
North     Apple     4000      July
South     Orange    5000      July
West      Apple     4000      June
East      Apple     5000      April
North     Pear      3000      August
East      Grape     9000      November
North     Orange    8000      October
East      Apple     10000     June
South     Pear      1000      December
North     Grape     10000     July
East      Grape     6000      February

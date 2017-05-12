#!/usr/bin/perl -w

###############################################################################
#
# This example demonstrates html formatted strings in cells.
#
# reverse('©'), April 2005, John McNamara, jmcnamara@cpan.org
#

use strict;
use Spreadsheet::WriteExcelXML;

my $workbook  = Spreadsheet::WriteExcelXML->new("html_string.xls");
my $worksheet = $workbook->add_worksheet();

$worksheet->set_column('B:B', 25);


# Write a string with some bold and italic text. Cell formatting can also
# be added.
#
my $str1    = 'Some <B>bold</B> and <I>italic</I> text';
my $format1 = $workbook->add_format(fg_color => 'yellow', border => 6);

$worksheet->write_html_string('B2', $str1);
$worksheet->write_html_string('B4', $str1, $format1);


# Write a string with subscript and superscript. Also increase the font
# size to make it more visible.
#
my $str2    = 'x<Sub><I>j</I></Sub><Sup>(n-1)</Sup>';
my $format2 = $workbook->add_format(size => 20);

$worksheet->write_html_string('B6', $str2, $format2);

# Write a multicoloured string.
#
my $str3    = '<Font html:Color="#FF0000">Red</Font>'  .
              '<Font> and </Font>'                     .
              '<Font html:Color="#0000FF">Blue</Font>';

$worksheet->write_html_string('B8', $str3);


__END__

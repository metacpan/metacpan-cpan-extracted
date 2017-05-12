#!/usr/bin/perl -w

###############################################################################
#
# Example of how to use the WriteExcelXML module to write internal and internal
# hyperlinks.
#
# If you wish to run this program and follow the hyperlinks you should create
# the following directory structure:
#
# C:\ -- Temp --+-- Europe
#               |
#               \-- Asia
#
#
# See also hyperlink1.pl for web URL examples.
#
# reverse('©'), February 2002, John McNamara, jmcnamara@cpan.org
#


use strict;
use Spreadsheet::WriteExcelXML;

# Create three workbooks:
#   C:\Temp\Europe\Ireland.xls
#   C:\Temp\Europe\Italy.xls
#   C:\Temp\Asia\China.xls
#

my $ireland   = Spreadsheet::WriteExcelXML->new('C:\Temp\Europe\Ireland.xls');

# Always check that the file was created.
die "Couldn't create new Excel file: $!.\n" unless defined $ireland;

my $ire_links      = $ireland->add_worksheet('Links');
my $ire_sales      = $ireland->add_worksheet('Sales');
my $ire_data       = $ireland->add_worksheet('Product Data');
my $ire_url_format = $ireland->add_format(
                                            color     => 'blue',
                                            underline => 1,
                                         );




my $italy     = Spreadsheet::WriteExcelXML->new('C:\Temp\Europe\Italy.xls');

# Always check that the file was created.
die "Couldn't create new Excel file: $!.\n" unless defined $ireland;

my $ita_links      = $italy->add_worksheet('Links');
my $ita_sales      = $italy->add_worksheet('Sales');
my $ita_data       = $italy->add_worksheet('Product Data');
my $ita_url_format = $italy->add_format(
                                            color     => 'blue',
                                            underline => 1,
                                       );




my $china     = Spreadsheet::WriteExcelXML->new('C:\Temp\Asia\China.xls');

# Always check that the file was created.
die "Couldn't create new Excel file: $!.\n" unless defined $ireland;

my $cha_links       = $china->add_worksheet('Links');
my $cha_sales       = $china->add_worksheet('Sales');
my $cha_data        = $china->add_worksheet('Product Data');
my $cha_url_format  = $china->add_format(
                                            color     => 'blue',
                                            underline => 1,
                                        );


# Add an alternative format
my $format = $ireland->add_format(color => 'green', bold => 1);
$ire_links->set_column('A:B', 25);


###############################################################################
#
# Examples of internal links
#
$ire_links->write('A1', 'Internal links', $format);

# Internal link
$ire_links->write_url('A2', '#Sales!A2', $ire_url_format);

# Internal link to a range
$ire_links->write_url('A3', '#Sales!A3:D3', $ire_url_format);

# Internal link with an alternative string
$ire_links->write_url('A4', '#Sales!A4', $ire_url_format, 'Link');

# Internal link with an alternative format
$ire_links->write_url('A5', '#Sales!A5', $format);

# Internal link with an alternative string and format
$ire_links->write_url('A6', '#Sales!A6', $ire_url_format, 'Link');

# Internal link (spaces in worksheet name)
$ire_links->write_url('A7', q{#'Product Data'!A7}, $ire_url_format);


###############################################################################
#
# Examples of external links
#
$ire_links->write('B1', 'External links', $format);

# External link to a local file
$ire_links->write_url('B2', 'Italy.xls', $ire_url_format);

# External link to a local file with worksheet
$ire_links->write_url('B3', 'Italy.xls#Sales!B3', $ire_url_format);

# External link to a local file with worksheet and alternative string
$ire_links->write_url('B4', 'Italy.xls#Sales!B4', $ire_url_format, 'Link');

# External link to a local file with worksheet and format
$ire_links->write_url('B5', 'Italy.xls#Sales!B5', $format);

# External link to a remote file, absolute path
$ire_links->write_url('B6', 'c:/Temp/Asia/China.xls', $ire_url_format);

# External link to a remote file, relative path
$ire_links->write_url('B7', '../Asia/China.xls', $ire_url_format);

# External link to a remote file with worksheet
$ire_links->write_url('B8', 'c:/Temp/Asia/China.xls#Sales!B8',
                            $ire_url_format);

# External link to a remote file with worksheet (with spaces in the name)
$ire_links->write_url('B9', q{c:/Temp/Asia/China.xls#'Product Data'!B9},
                            $ire_url_format);


###############################################################################
#
# Some utility links to return to the main sheet
#
$ire_sales->write_url('A2', '#Links!A2', $ire_url_format, 'Back');
$ire_sales->write_url('A3', '#Links!A3', $ire_url_format, 'Back');
$ire_sales->write_url('A4', '#Links!A4', $ire_url_format, 'Back');
$ire_sales->write_url('A5', '#Links!A5', $ire_url_format, 'Back');
$ire_sales->write_url('A6', '#Links!A6', $ire_url_format, 'Back');
$ire_data-> write_url('A7', '#Links!A7', $ire_url_format, 'Back');

$ita_links->write_url('A1', 'Ireland.xls#Links!B2', $ita_url_format, 'Back');
$ita_sales->write_url('B3', 'Ireland.xls#Links!B3', $ita_url_format, 'Back');
$ita_sales->write_url('B4', 'Ireland.xls#Links!B4', $ita_url_format, 'Back');
$ita_sales->write_url('B5', 'Ireland.xls#Links!B5', $ita_url_format, 'Back');
$cha_links->write_url('A1', 'c:/Temp/Europe/Ireland.xls#Links!B6',
                             $cha_url_format, 'Back');
$cha_sales->write_url('B8', 'c:/Temp/Europe/Ireland.xls#Links!B8',
                             $cha_url_format, 'Back');
$cha_data-> write_url('B9', 'c:/Temp/Europe/Ireland.xls#Links!B9',
                             $cha_url_format, 'Back');


__END__

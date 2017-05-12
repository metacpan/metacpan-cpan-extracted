#!/usr/bin/perl -wl

##############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Regression test the ouput from a typical program against the stored output
# from a previous version.
#
# reverse('©'), April 2005, John McNamara, jmcnamara@cpan.org
#


use strict;

use Spreadsheet::WriteExcelXML;
use Test::More tests => 1;





##############################################################################
#
# Create a new typical WriteExcelXML file.
#
my $test_file  = "temp_test_file.xml";
my $workbook   = Spreadsheet::WriteExcelXML->new($test_file);

my $worksheet  = $workbook->add_worksheet('Demo');
my $worksheet2 = $workbook->add_worksheet('Another sheet');
my $worksheet3 = $workbook->add_worksheet('And another');

my $bold       = $workbook->add_format(bold => 1);


# Write a general heading
$worksheet->set_column('A:A', 48, $bold);
$worksheet->set_column('B:B', 20       );
$worksheet->set_row   (0,     40       );

my $heading  = $workbook->add_format(
                                        bold    => 1,
                                        color   => 'blue',
                                        size    => 16,
                                        merge   => 1,
                                        align  => 'vcenter',
                                        );

my @headings = ('Features of Spreadsheet::WriteExcelXML', '');
$worksheet->write_row('A1', \@headings, $heading);


# Some text examples
my $text_format  = $workbook->add_format(
                                            bold    => 1,
                                            italic  => 1,
                                            color   => 'red',
                                            size    => 18,
                                            font    =>'Lucida Calligraphy'
                                        );

$worksheet->write('A2', "Text");
$worksheet->write('B2', "Hello Excel");
$worksheet->write('A3', "Formatted text");
$worksheet->write('B3', "Hello Excel", $text_format);

# Some numeric examples
my $num1_format  = $workbook->add_format(num_format => '$#,##0.00');
my $num2_format  = $workbook->add_format(num_format => ' d mmmm yyy');


$worksheet->write('A4', "Numbers");
$worksheet->write('B4', 1234.56);
$worksheet->write('A5', "Formatted numbers");
$worksheet->write('B5', 1234.56, $num1_format);
$worksheet->write('A6', "Formatted numbers");
$worksheet->write('B6', 37257, $num2_format);


# Formulae
$worksheet->set_selection('B7');
$worksheet->write('A7', 'Formulas and functions, "=SIN(PI()/4)"');
$worksheet->write('B7', '=SIN(PI()/4)');


# Hyperlinks
my $url_format  = $workbook->add_format(
                                            underline => 1,
                                            color     => 'blue',
                                        );

$worksheet->write('A8', "Hyperlinks");
$worksheet->write('B8',  'http://www.perl.com/', $url_format);


# Misc
$worksheet->write('A17', "Page/printer setup");
$worksheet->write('A18', "Multiple worksheets");


$workbook->close();


##############################################################################
#
# Re-open and reread the Excel file.
#
open XML, $test_file or die "Couldn't open $test_file: $!\n";
my $swex_data = do {local $/; <XML>};
   $swex_data =~ s/[\r\n]+/ /g;

close XML;
unlink $test_file;


##############################################################################
#
# Read the data from the Excel file in the __DATA__ section
#
my $test_data = do {local $/; <DATA>};
   $test_data =~ s/[\r\n]+/ /g;


##############################################################################
#
# Run the tests
#
is($swex_data, $test_data, "Regression test");


__DATA__
<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook
    xmlns:x="urn:schemas-microsoft-com:office:excel"
    xmlns="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
    <Styles>
        <Style ss:ID="s21">
            <Font ss:Bold="1"/>
        </Style>
        <Style ss:ID="s22">
            <Alignment
                ss:Horizontal="CenterAcrossSelection"
                ss:Vertical="Center"/>
            <Font
                ss:Size="16"
                ss:Color="#0000FF"
                ss:Bold="1"/>
        </Style>
        <Style ss:ID="s23">
            <Font
                ss:FontName="Lucida Calligraphy"
                ss:Size="18"
                ss:Color="#FF0000"
                ss:Bold="1"
                ss:Italic="1"/>
        </Style>
        <Style ss:ID="s24">
            <NumberFormat ss:Format="$#,##0.00"/>
        </Style>
        <Style ss:ID="s25">
            <NumberFormat ss:Format=" d mmmm yyy"/>
        </Style>
        <Style ss:ID="s26">
            <Font
                ss:Color="#0000FF"
                ss:Underline="Single"/>
        </Style>
    </Styles>
    <Worksheet ss:Name="Demo">
        <Table ss:ExpandedColumnCount="2" ss:ExpandedRowCount="18">
            <Column ss:StyleID="s21" ss:AutoFitWidth="0" ss:Width="255.75"/>
            <Column ss:AutoFitWidth="0" ss:Width="108.75"/>
            <Row ss:AutoFitHeight="0" ss:Height="39.75">
                <Cell ss:StyleID="s22">
                    <Data ss:Type="String">Features of Spreadsheet::WriteExcelXML</Data>
                </Cell>
                <Cell ss:StyleID="s22"/>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Text</Data>
                </Cell>
                <Cell>
                    <Data ss:Type="String">Hello Excel</Data>
                </Cell>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Formatted text</Data>
                </Cell>
                <Cell ss:StyleID="s23">
                    <Data ss:Type="String">Hello Excel</Data>
                </Cell>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Numbers</Data>
                </Cell>
                <Cell>
                    <Data ss:Type="Number">1234.56</Data>
                </Cell>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Formatted numbers</Data>
                </Cell>
                <Cell ss:StyleID="s24">
                    <Data ss:Type="Number">1234.56</Data>
                </Cell>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Formatted numbers</Data>
                </Cell>
                <Cell ss:StyleID="s25">
                    <Data ss:Type="Number">37257</Data>
                </Cell>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Formulas and functions, &quot;=SIN(PI()/4)&quot;</Data>
                </Cell>
                <Cell ss:Formula="=SIN(PI()/4)"/>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Hyperlinks</Data>
                </Cell>
                <Cell ss:StyleID="s26" ss:HRef="http://www.perl.com/">
                    <Data ss:Type="String">http://www.perl.com/</Data>
                </Cell>
            </Row>
            <Row ss:Index="17">
                <Cell>
                    <Data ss:Type="String">Page/printer setup</Data>
                </Cell>
            </Row>
            <Row>
                <Cell>
                    <Data ss:Type="String">Multiple worksheets</Data>
                </Cell>
            </Row>
        </Table>
    </Worksheet>
    <Worksheet ss:Name="Another sheet">
    </Worksheet>
    <Worksheet ss:Name="And another">
    </Worksheet>
</Workbook>

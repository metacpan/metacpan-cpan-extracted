#!/usr/bin/perl -w

###############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Tests the set_row() method with extended cell limits.
#
# reverse('©'), July 2004, John McNamara, jmcnamara@cpan.org
#


use strict;
use Spreadsheet::WriteExcelXML;
use Test::More tests => 10;


my @test_data;
my @swex_data;

#
# Create a new Excel XML file with row data set.
#
my $test_file = "temp_test_file.xml";
my $workbook  = Spreadsheet::WriteExcelXML->new($test_file);
my $worksheet = $workbook->add_worksheet();
my $bold      = $workbook->add_format(bold   => 1);
my $italic    = $workbook->add_format(italic => 1);

$worksheet->set_row($_, 45.75          ) for 0 .. 9;
$worksheet->set_row(13, undef, $bold   );
$worksheet->set_row(14, undef, $italic );
$worksheet->set_row(15, undef, $bold   );
$worksheet->set_row(17, undef, undef, 1);
$worksheet->set_row(19, 9,     undef, 1);
$worksheet->set_row($_, undef, $bold    ) for 1_048_572.. 1_048_576; # 1 over limit.

# Split the 0 .. 9 <Row> range.
$worksheet->write('D5', 8);
$workbook->close();

# Re-open and reread the Excel file.
open XML, $test_file or die "Couldn't open $test_file: $!\n";

while (<XML>) {
    if (/\s+<Row /) {
        s/^\s+//;
        s/\s+$//;
        push @swex_data, $_;
    }
}

close XML;
unlink $test_file;


# Read the Excel file in the __DATA__ section
while (<DATA>) {
    if (/\s+<Row /) {
        s/^\s+//;
        s/\s+$//;
        push @test_data, $_;
    }
}


# Check for the same number of elements.
is(@swex_data, @test_data, " \tCheck for data size");

# Pad the SWEX data if necessary.
push @swex_data, ('') x (@test_data -@swex_data);

# Test that the SWEX elements and Excel are the same.
for my $i (0 .. @test_data -1) {
    is($swex_data[$i],$test_data[$i], " \tTesting set_row()");

}


# The following file was created by Excel. Some redundant data is removed.
__DATA__
<?xml version="1.0"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
  <Styles>
  <Style ss:ID="Default" ss:Name="Normal">
   <Alignment ss:Vertical="Bottom"/>
   <Borders/>
   <Font/>
   <Interior/>
   <NumberFormat/>
   <Protection/>
  </Style>
  <Style ss:ID="s21">
   <Font x:Family="Swiss" ss:Bold="1"/>
  </Style>
  <Style ss:ID="s22">
   <Font x:Family="Swiss" ss:Italic="1"/>
  </Style>
 </Styles>
 <Worksheet ss:Name="Sheet1">
  <Table ss:ExpandedColumnCount="4" ss:ExpandedRowCount="1048576" x:FullColumns="1"
   x:FullRows="1">
   <Row ss:AutoFitHeight="0" ss:Height="45.75" ss:Span="3"/>
   <Row ss:Index="5" ss:AutoFitHeight="0" ss:Height="45.75">
    <Cell ss:Index="4"><Data ss:Type="Number">8</Data></Cell>
   </Row>
   <Row ss:AutoFitHeight="0" ss:Height="45.75" ss:Span="4"/>
   <Row ss:Index="14" ss:StyleID="s21"/>
   <Row ss:StyleID="s22"/>
   <Row ss:StyleID="s21"/>
   <Row ss:Index="18" ss:Hidden="1"/>
   <Row ss:Index="20" ss:AutoFitHeight="0" ss:Height="9" ss:Hidden="1"/>
   <Row ss:Index="1048573" ss:StyleID="s21" ss:Span="3"/>
  </Table>
 </Worksheet>
</Workbook>

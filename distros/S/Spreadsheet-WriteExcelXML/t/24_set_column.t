#!/usr/bin/perl -w

###############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Tests the set_column() method with extended cell limits.
#
# reverse('©'), July 2004, John McNamara, jmcnamara@cpan.org
#


use strict;
use Spreadsheet::WriteExcelXML;
use Test::More tests => 10;


my @test_data;
my @swex_data;

#
# Create a new Excel XML file with column data set.
#
my $test_file = "temp_test_file.xml";
my $workbook  = Spreadsheet::WriteExcelXML->new($test_file);
my $worksheet = $workbook->add_worksheet();
my $bold      = $workbook->add_format(bold   => 1);
my $italic    = $workbook->add_format(italic => 1);

$worksheet->set_column('A:J',   20             );
$worksheet->set_column('D:D',   10             ); # Split previous range.
$worksheet->set_column('M:M',   undef, $bold   );
$worksheet->set_column('O:O',   undef, $italic );
$worksheet->set_column('Q:Q',   undef, $bold   );
$worksheet->set_column('S:S',   undef, undef, 1);
$worksheet->set_column('U:U',   2,     undef, 1);
$worksheet->set_column('XEY:XFD', undef, $bold   );
$worksheet->set_column('XFE:XFF', undef, $bold   ); # Past limits.

$worksheet->write('D5', 8);
$workbook->close();

# Re-open and reread the Excel file.
open XML, $test_file or die "Couldn't open $test_file: $!\n";

while (<XML>) {
    if (/\s+<Column /) {
        s/^\s+//;
        s/\s+$//;
        push @swex_data, $_;
    }
}

close XML;
unlink $test_file;


# Read the Excel file in the __DATA__ section
while (<DATA>) {
    if (/\s+<Column /) {
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
    is($swex_data[$i],$test_data[$i], " \tTesting set_column()");

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
   <Alignment ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:Bold="1"/>
   <Interior/>
   <NumberFormat/>
   <Protection/>
  </Style>
  <Style ss:ID="s22">
   <Alignment ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:Italic="1"/>
   <Interior/>
   <NumberFormat/>
   <Protection/>
  </Style>
 </Styles>
 <Worksheet ss:Name="Sheet1">
  <Table ss:ExpandedColumnCount="256" ss:ExpandedRowCount="5" x:FullColumns="1"
   x:FullRows="1">
   <Column ss:AutoFitWidth="0" ss:Width="108.75" ss:Span="2"/>
   <Column ss:Index="4" ss:AutoFitWidth="0" ss:Width="56.25"/>
   <Column ss:AutoFitWidth="0" ss:Width="108.75" ss:Span="5"/>
   <Column ss:Index="13" ss:StyleID="s21" ss:AutoFitWidth="0"/>
   <Column ss:Index="15" ss:StyleID="s22" ss:AutoFitWidth="0"/>
   <Column ss:Index="17" ss:StyleID="s21" ss:AutoFitWidth="0"/>
   <Column ss:Index="19" ss:Hidden="1" ss:AutoFitWidth="0"/>
   <Column ss:Index="21" ss:Hidden="1" ss:AutoFitWidth="0" ss:Width="14.25"/>
   <Column ss:Index="16379" ss:StyleID="s21" ss:AutoFitWidth="0" ss:Span="5"/>
   <Row ss:Index="5">
    <Cell ss:Index="4"><Data ss:Type="Number">8</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Selected/>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
</Workbook>

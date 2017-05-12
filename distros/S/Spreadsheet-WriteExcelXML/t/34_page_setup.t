#!/usr/bin/perl -w

###############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Tests the page setup methods.
#
# reverse('©'), November 2004, John McNamara, jmcnamara@cpan.org
#


use strict;
use Spreadsheet::WriteExcelXML;
use Test::More tests => 34;

my @captions;

##############################################################################
#
# Create a new Excel XML file with different formats on each page.
#
my $test_file  = "temp_test_file.xml";
my $workbook   = Spreadsheet::WriteExcelXML->new($test_file);
my $worksheet;


# The captions are written to the worksheet so that it can be inspected
# visually if required.


# Test
push @captions, "Testing set_landscape().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_landscape();


# Test: Portrait is the default so the following shouldn't have an effect.
push @captions, "Testing set_portrait(). No effect.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_portrait();


# Test:
push @captions, "Testing set_paper(), Default. No effect.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_paper();


# Test:
push @captions, "Testing set_paper(), A3.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_paper(8);


# Test:
push @captions, "Testing center_horizontally().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->center_horizontally();

# Test:
push @captions, "Testing center_vertically().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->center_vertically();


# Test:
push @captions, "Testing set_margins().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margins(0.5);


# Test:
push @captions, "Testing set_margins_LR().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margins_LR(0.5);


# Test:
push @captions, "Testing set_margins_TB().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margins_TB(0.5);


# Test:
push @captions, "Testing set_margin_left().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margin_left(0.5);


# Test:
push @captions, "Testing set_margin_right().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margin_right(0.5);


# Test:
push @captions, "Testing set_margin_top().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margin_top(0.5);


# Test:
push @captions, "Testing set_margin_bottom().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margin_bottom(0.5);


# Test:
push @captions, "Testing the margin defaults. No effect.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_margin_left  (0.75);
$worksheet->set_margin_right (0.75);
$worksheet->set_margin_top   (1);
$worksheet->set_margin_bottom(1);


# Test:
push @captions, "Testing set_header.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_header('&LHello');


# Test:
push @captions, "Testing set_footer.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_footer('&CHello');


# Test:
push @captions, "Testing set_header with margin.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_header('&LHello', 2);


# Test:
push @captions, "Testing Testing set_footer with margin.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_footer('&CHello', 2);


# Test:
push @captions, "Testing hide_gridlines. No effect.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->hide_gridlines(1);


# Test:
push @captions, "Testing hide_gridlines. Screen gridlines off.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->hide_gridlines(2);


# Test:
push @captions, "Testing print_gridlines.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->print_gridlines();


# Test:
push @captions, "Testing print_gridlines.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->print_gridlines(1);


# Test:
push @captions, "Testing print_gridlines. No effect.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->print_gridlines(0);


# Test:
push @captions, "Testing print_row_col_headers.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->print_row_col_headers();


# Test:
push @captions, "Testing fit_to_pages. 1 x 1.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->fit_to_pages(1);


# Test:
push @captions, "Testing fit_to_pages. 1 x 1.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->fit_to_pages(1, 1);


# Test:
push @captions, "Testing fit_to_pages. 2 x 1.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->fit_to_pages(2);


# Test:
push @captions, "Testing fit_to_pages. 2 x 3.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->fit_to_pages(2, 3);


# Test:
push @captions, "Testing set_print_scale.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_print_scale(75);


# Test:
push @captions, "Testing set_h_pagebreaks().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_h_pagebreaks(2);


# Test:
push @captions, "Testing set_h_pagebreaks().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_h_pagebreaks(2, 4, 6);


# Test:
push @captions, "Testing set_v_pagebreaks().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_v_pagebreaks(2);


# Test:
push @captions, "Testing set_v_pagebreaks().";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_v_pagebreaks(2, 4, 6);


# Test:
push @captions, "Testing vertical and horizontal pagebreaks.";
$worksheet = $workbook->add_worksheet();
$worksheet->write('A1', $captions[-1]);
$worksheet->set_h_pagebreaks(2);
$worksheet->set_v_pagebreaks(3);



$workbook->close();


##############################################################################
#
# Re-open and reread the Excel file.
#
open XML, $test_file or die "Couldn't open $test_file: $!\n";
my @swex_data = extract_setup(*XML);
close XML;
unlink $test_file;


##############################################################################
#
# Read the data from the Excel file in the __DATA__ section
#
my @test_data = extract_setup(*DATA);


##############################################################################
#
# Pad the SWEX and test data if necessary.
#

push @swex_data, ('') x (@test_data -@swex_data);
push @test_data, ('') x (@swex_data -@test_data);


##############################################################################
#
# Run the tests
#
for my $i (0 .. @test_data -1) {
    is($swex_data[$i], $test_data[$i], $captions[$i]);

}


##############################################################################
#
# Extract <Cell> elements from a given filehandle.
#
sub extract_setup {

    my $fh     = $_[0];
    my $in_opt = 0;
    my $setup    = '';
    my @options;

    while (<$fh>) {
        s/^\s+([<| ])/$1/;
        s/\s+$//;

        next if m[^<ProtectObjects>];
        next if m[^<ProtectScenarios>];
        next if m[^<Selected/>];
        next if m[^<PaperSizeIndex>9];
        next if m[^<VerticalResolution>];
        next if m[^<HorizontalResolution>];
        next if m[^</?PageBreaks];

        $in_opt = 1 if (m[^<WorksheetOptions] .. m[^</WorksheetOptions]);

        $setup .= $_ if $in_opt and not m[</?Worksheet];


        if (m[^</Worksheet>]) {
            # Remove Excel's default empty <Print>.
            $setup =~ s[<Print><ValidPrinterInfo/></Print>][];
            push @options, $setup;
            $in_opt = 0;
            $setup  = '';
        }
    }

    return @options;
}


# The following data was generated by Excel.
__DATA__
<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
 <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">
  <Version>11.5606</Version>
 </DocumentProperties>
 <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">
  <DownloadComponents/>
  <LocationOfComponents HRef="file:///D:\"/>
 </OfficeDocumentSettings>
 <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">
  <WindowHeight>10005</WindowHeight>
  <WindowWidth>10005</WindowWidth>
  <WindowTopX>120</WindowTopX>
  <WindowTopY>135</WindowTopY>
  <ProtectStructure>False</ProtectStructure>
  <ProtectWindows>False</ProtectWindows>
 </ExcelWorkbook>
 <Styles>
  <Style ss:ID="Default" ss:Name="Normal">
   <Alignment ss:Vertical="Bottom"/>
   <Borders/>
   <Font/>
   <Interior/>
   <NumberFormat/>
   <Protection/>
  </Style>
 </Styles>
 <Worksheet ss:Name="Sheet1">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_landscape().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Layout x:Orientation="Landscape"/>
   </PageSetup>
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <Selected/>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet2">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_portrait(). No effect.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet3">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_paper(), Default. No effect.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet4">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_paper(), A3.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <PaperSizeIndex>8</PaperSizeIndex>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet5">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing center_horizontally().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Layout x:CenterHorizontal="1"/>
   </PageSetup>
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet6">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing center_vertically().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Layout x:CenterVertical="1"/>
   </PageSetup>
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet7">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margins().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Bottom="0.5" x:Left="0.5" x:Right="0.5" x:Top="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet8">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margins_LR().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Left="0.5" x:Right="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet9">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margins_TB().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Bottom="0.5" x:Top="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet10">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margin_left().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Left="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet11">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margin_right().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Right="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet12">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margin_top().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Top="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet13">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_margin_bottom().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <PageMargins x:Bottom="0.5"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet14">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing the margin defaults. No effect.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet15">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_header.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Data="&amp;LHello"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet16">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_footer.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Footer x:Data="&amp;CHello"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet17">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_header with margin.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="2" x:Data="&amp;LHello"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet18">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing Testing set_footer with margin.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Footer x:Margin="2" x:Data="&amp;CHello"/>
   </PageSetup>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet19">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing hide_gridlines. No effect.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet20">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing hide_gridlines. Screen gridlines off.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <DoNotDisplayGridlines/>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet21">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing print_gridlines.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
    <Gridlines/>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet22">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing print_gridlines.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
    <Gridlines/>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet23">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing print_gridlines. No effect.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet24">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing print_row_col_headers.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
    <RowColHeadings/>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet25">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing fit_to_pages. 1 x 1.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <FitToPage/>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet26">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing fit_to_pages. 1 x 1.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <FitToPage/>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet27">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing fit_to_pages. 2 x 1.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <FitToPage/>
   <Print>
    <FitWidth>2</FitWidth>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet28">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing fit_to_pages. 2 x 3.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <FitToPage/>
   <Print>
    <FitWidth>2</FitWidth>
    <FitHeight>3</FitHeight>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet29">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_print_scale.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <Scale>75</Scale>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>
 <Worksheet ss:Name="Sheet30">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_h_pagebreaks().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
  <PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">
   <RowBreaks>
    <RowBreak>
     <Row>2</Row>
    </RowBreak>
   </RowBreaks>
  </PageBreaks>
 </Worksheet>
 <Worksheet ss:Name="Sheet31">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_h_pagebreaks().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
  <PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">
   <RowBreaks>
    <RowBreak>
     <Row>2</Row>
    </RowBreak>
    <RowBreak>
     <Row>4</Row>
    </RowBreak>
    <RowBreak>
     <Row>6</Row>
    </RowBreak>
   </RowBreaks>
  </PageBreaks>
 </Worksheet>
 <Worksheet ss:Name="Sheet32">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_v_pagebreaks().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
  <PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">
   <ColBreaks>
    <ColBreak>
     <Column>2</Column>
    </ColBreak>
   </ColBreaks>
  </PageBreaks>
 </Worksheet>
 <Worksheet ss:Name="Sheet33">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing set_v_pagebreaks().</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
  <PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">
   <ColBreaks>
    <ColBreak>
     <Column>2</Column>
    </ColBreak>
    <ColBreak>
     <Column>4</Column>
    </ColBreak>
    <ColBreak>
     <Column>6</Column>
    </ColBreak>
   </ColBreaks>
  </PageBreaks>
 </Worksheet>
 <Worksheet ss:Name="Sheet34">
  <Table ss:ExpandedColumnCount="1" ss:ExpandedRowCount="1" x:FullColumns="1"
   x:FullRows="1">
   <Row>
    <Cell><Data ss:Type="String">Testing vertical and horizontal pagebreaks.</Data></Cell>
   </Row>
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <Print>
    <ValidPrinterInfo/>
    <VerticalResolution>0</VerticalResolution>
   </Print>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
  <PageBreaks xmlns="urn:schemas-microsoft-com:office:excel">
   <ColBreaks>
    <ColBreak>
     <Column>3</Column>
    </ColBreak>
   </ColBreaks>
   <RowBreaks>
    <RowBreak>
     <Row>2</Row>
    </RowBreak>
   </RowBreaks>
  </PageBreaks>
 </Worksheet>
</Workbook>

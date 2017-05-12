#!/usr/bin/perl -w

###############################################################################
#
# An example of how to use Spreadsheet::WriteExcelXML to create a web page
# with a web component interactive spreadsheet.
#
# Only works with Internet Explorer.
#
# reverse('©'), May 2004, John McNamara, jmcnamara@cpan.org
#


use strict;

use strict;
use Spreadsheet::WriteExcelXML;

#
# Change the following to suit.
#
my $excel_file    = "web_component.xml";
my $html_file     = "web_component.htm";
my $excel_version = 2003;
my $clsid;


#
# Create an Excel XML file.
#
my $workbook   = Spreadsheet::WriteExcelXML->new($excel_file);

die "Couldn't create new Excel file: $!.\n" unless defined $workbook;

my $worksheet  = $workbook->add_worksheet();
my $bold       = $workbook->add_format(bold => 1);
my $currency   = $workbook->add_format(num_format => '$#,##0.00');
my $total1     = $workbook->add_format(bold       => 1, top => 6);
my $total2     = $workbook->add_format(bold       => 1,
                                       top        => 6,
                                       num_format => '$#,##0.00');


$worksheet->write('A1', 'Quarter',    $bold  );
$worksheet->write('A2',         1,    $bold  );
$worksheet->write('A3',         2,    $bold  );
$worksheet->write('A4',         3,    $bold  );
$worksheet->write('A5',         4,    $bold  );
$worksheet->write('A6', 'Total',      $total1);



$worksheet->write('B1', 'Sales',       $bold    );
$worksheet->write('B2',   10000,       $currency);
$worksheet->write('B3',   12000,       $currency);
$worksheet->write('B4',    9000,       $currency);
$worksheet->write('B5',   11000,       $currency);
$worksheet->write('B6', '=SUM(B2:B5)', $total2  );


$workbook->close();


#

# Reread the Excel XML data.
#
# It would be better to initially write the data to a scalar using IO::Scalar
# or the perl 5.8 open scalar feature.
#
open XML, $excel_file or die "Couldn't open $excel_file: $!\n";

my $excel_xml_data = do {local $/; <XML>};

close XML;

# Escape XML characters.
for ($excel_xml_data) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g; # "
        s/\r/&#13;/g;
        s/\n/&#10;/g;
}



$clsid = "CLSID:0002E541-0000-0000-C000-000000000046" if $excel_version == 2002;
$clsid = "CLSID:0002E559-0000-0000-C000-000000000046" if $excel_version == 2003;



#
# Simple template mechanism. Use HTML::Template or the Template::Toolkit for
# real applications.
#
my $template =  do {local $/; <DATA>};
   $template =~ s/__EXCEL_XML_DATA__/$excel_xml_data/;
   $template =~ s/__SPREADSHEET_CLSID__/$clsid/;
   $template =~ s/__EXCEL_VERSION__/$excel_version/;


open HTML, "> $html_file" or die "Couldn't open $$html_file: $!\n";
print HTML $template;



__END__
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">

    <body>
        <div id="Spreadsheet" align=center x:publishsource="Excel">
            <object id="Spreadsheet" classid="__SPREADSHEET_CLSID__">
                <param name=DisplayTitleBar value=false>
                <param name=Autofit  value=true>
                <param name=DataType value=XMLData>
                <param name=XMLData  value="__EXCEL_XML_DATA__">
                <p>
                    To use this Web page interactively, you must have Microsoft®
                    Internet Explorer 5.01 Service Pack 2 (SP2) or later and
                    the Microsoft Office __EXCEL_VERSION__ Web Components.
                </p>
                <p>
                    See the <a href="http://r.office.microsoft.com/r/rlidmsowcpub?clid=1033&amp;p1=Excel">
                    Microsoft Office Web site</a> for more information.
                </p>
            </object>
        </div>
    </body>
</html>


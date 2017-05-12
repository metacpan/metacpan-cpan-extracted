# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 7 };
use OpenOffice::Parse::SXC;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.



test();


sub test {
  my $SXC		= OpenOffice::Parse::SXC->new;
  $SXC->parse( *DATA ) && ok(1);
  use Data::Dumper;
  my @rows		= $SXC->parse_sxc_rows;
  ok( scalar @{$rows[0]} == 7 );

  ok( $rows[0][0] eq "This spreadsheet is a test sheet for the module OpenOffice::Parse::SXC" );

  ok( $rows[4][4] eq "5091.75" );

  ok( scalar @rows == 21 );

  ok( $rows[19][0] eq "This row (11) in spreadsheet test.sxc in sheet \'sheet2\' has five spaces now:     .  That\'s it." );

}




__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE office:document-content PUBLIC "-//OpenOffice.org//DTD OfficeDocument 1.0//EN" "office.dtd"><office:document-content xmlns:office="http://openoffice.org/2000/office" xmlns:style="http://openoffice.org/2000/style" xmlns:text="http://openoffice.org/2000/text" xmlns:table="http://openoffice.org/2000/table" xmlns:draw="http://openoffice.org/2000/drawing" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:number="http://openoffice.org/2000/datastyle" xmlns:svg="http://www.w3.org/2000/svg" xmlns:chart="http://openoffice.org/2000/chart" xmlns:dr3d="http://openoffice.org/2000/dr3d" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="http://openoffice.org/2000/form" xmlns:script="http://openoffice.org/2000/script" office:class="spreadsheet" office:version="1.0"><office:script/><office:font-decls><style:font-decl style:name="Arial Unicode MS" fo:font-family="&apos;Arial Unicode MS&apos;" style:font-pitch="variable"/><style:font-decl style:name="HG Mincho Light J" fo:font-family="&apos;HG Mincho Light J&apos;" style:font-pitch="variable"/><style:font-decl style:name="Albany" fo:font-family="Albany" style:font-family-generic="swiss" style:font-pitch="variable"/></office:font-decls><office:automatic-styles><style:style style:name="co1" style:family="table-column"><style:properties fo:break-before="auto" style:column-width="0.8925inch"/></style:style><style:style style:name="co2" style:family="table-column"><style:properties fo:break-before="auto" style:column-width="1.1327inch"/></style:style><style:style style:name="ro1" style:family="table-row"><style:properties fo:break-before="auto"/></style:style><style:style style:name="ta1" style:family="table" style:master-page-name="Default"><style:properties table:display="true"/></style:style><number:percentage-style style:name="N11" style:family="data-style"><number:number number:decimal-places="2" number:min-integer-digits="1"/><number:text>%</number:text></number:percentage-style><style:style style:name="ce1" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N11"/></office:automatic-styles><office:body><table:table table:name="Sheet1" table:style-name="ta1"><table:table-column table:style-name="co1" table:default-cell-style-name="Default"/><table:table-column table:style-name="co1" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co1" table:default-cell-style-name="Default"/><table:table-column table:style-name="co1" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co1" table:number-columns-repeated="2" table:default-cell-style-name="Default"/><table:table-column table:style-name="co2" table:default-cell-style-name="Default"/><table:table-row table:style-name="ro1"><table:table-cell><text:p>This spreadsheet is a test sheet for the module OpenOffice::Parse::SXC</text:p></table:table-cell><table:table-cell table:number-columns-repeated="6"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:number-columns-repeated="7"/></table:table-row><table:table-row-group><table:table-row table:style-name="ro1"><table:table-cell><text:p>Group 1</text:p></table:table-cell><table:table-cell table:number-columns-repeated="6"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="12345"><text:p>12345</text:p></table:table-cell><table:table-cell table:value-type="percentage" table:value="0.07"><text:p>7.00%</text:p></table:table-cell><table:table-cell table:formula="=[.A4]*[.B4]" table:value-type="float" table:value="864.15"><text:p>864.15</text:p></table:table-cell><table:table-cell table:value-type="percentage" table:value="0.075"><text:p>7.50%</text:p></table:table-cell><table:table-cell table:formula="=[.A4]*[.D4]" table:value-type="float" table:value="925.875"><text:p>925.88</text:p></table:table-cell><table:table-cell/><table:table-cell table:formula="=[.A4]+[.C4]+[.E4]" table:value-type="float" table:value="14135.025"><text:p>14135.03</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="67890"><text:p>67890</text:p></table:table-cell><table:table-cell table:value-type="percentage" table:value="0.07"><text:p>7.00%</text:p></table:table-cell><table:table-cell table:formula="=[.A5]*[.B5]" table:value-type="float" table:value="4752.3"><text:p>4752.3</text:p></table:table-cell><table:table-cell table:value-type="percentage" table:value="0.075"><text:p>7.50%</text:p></table:table-cell><table:table-cell table:formula="=[.A5]*[.D5]" table:value-type="float" table:value="5091.75"><text:p>5091.75</text:p></table:table-cell><table:table-cell/><table:table-cell table:formula="=[.A5]+[.C5]+[.E5]" table:value-type="float" table:value="77734.05"><text:p>77734.05</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1" table:number-rows-repeated="3"><table:table-cell table:number-columns-repeated="7"/></table:table-row></table:table-row-group><table:table-row table:style-name="ro1" table:number-rows-repeated="31991"><table:table-cell table:number-columns-repeated="7"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:number-columns-repeated="7"/></table:table-row></table:table><table:table table:name="Sheet2" table:style-name="ta1"><table:table-column table:style-name="co1" table:default-cell-style-name="Default"/><table:table-row table:style-name="ro1"><table:table-cell><text:p>This is sheet 2</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="1"><text:p>1</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="2"><text:p>2</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="3"><text:p>3</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="4"><text:p>4</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:value-type="float" table:value="5"><text:p>5</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:formula="=SUM([.A3:.A7])" table:value-type="float" table:value="15"><text:p>15</text:p></table:table-cell></table:table-row><table:table-row table:style-name="ro1" table:number-rows-repeated="2"><table:table-cell/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell><text:p>This row (11) in spreadsheet test.sxc in sheet &apos;sheet2&apos; has five spaces now: <text:s text:c="4"/>. <text:s/>That&apos;s it.</text:p></table:table-cell></table:table-row></table:table><table:table table:name="Sheet3" table:style-name="ta1"><table:table-column table:style-name="co1" table:default-cell-style-name="Default"/><table:table-row table:style-name="ro1"><table:table-cell/></table:table-row></table:table></office:body></office:document-content>

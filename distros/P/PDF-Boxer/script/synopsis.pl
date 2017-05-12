#!/usr/bin/perl

use PDF::Boxer::SpecParser;
use PDF::Boxer;

$pdfml = <<'__EOP__';
<column max_width="595" max_height="842">
  <column border_color="blue" border="2">
    <row>
      <image src="t/lecstor.gif" align="center" valign="center" padding="10" scale="60" />
      <column grow="1" padding="10 10 10 0">
        <text padding="3" align="right" size="20">
          Lecstor Pty Ltd
        </text>
        <text padding="3" align="right" size="14">
          123 Example St, Somewhere, Qld 4879
        </text>
      </column>
    </row>
    <row padding="15 0">
      <text padding="20" size="14">
        Mr G Client
        Shop 2 Some Centre, Retail Rd
        Somewhere, NSW 2000
      </text>
      <column padding="20" border_color="red" grow="1">
        <text size="16" align="right" font="Helvetica-Bold">
          Tax Invoice No. 123
        </text>
        <text size="14" align="right">
          Issued 01/01/2011
        </text>
        <text size="14" align="right" font="Helvetica-Bold">
          Due 14/01/2011
        </text>
      </column>
    </row>
  </column>
  <grid padding="10">
    <row font="Helvetica-Bold" padding="0">
      <text align="center" padding="0 10">Name</text>
      <text grow="1" align="center" padding="0 10">Description</text>
      <text padding="0 10" align="center">GST Amount</text>
      <text padding="0 10" align="center">Payable Amount</text>
    </row>
    <row margin="10 0 0 0">
      <text padding="0 5">Web Services</text>
      <text name="ItemText2" grow="1" padding="0 5">
        a long description which needs to be wrapped to fit in the box
      </text>
      <text padding="0 5" align="right">$9999.99</text>
      <text padding="0 5" align="right">$99999.99</text>
    </row>
  </grid>
</column>
__EOP__

$parser = PDF::Boxer::SpecParser->new;
$spec = $parser->parse($pdfml);

$boxer = PDF::Boxer->new( doc => { file => 'synopsis_output.pdf' } );

$boxer->add_to_pdf($spec);
$boxer->finish;

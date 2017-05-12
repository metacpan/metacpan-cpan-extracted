#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use PDF::Boxer;
use PDF::Boxer::SpecParser;

my $spec = <<'__EOP__';
<doc name="Main" max_width="595" max_height="842">

  <column name ="Page 1">
    <column name="Header">
      <row name="Head" border="0 0 1 0">
        <image src="t/lecstor.gif" name="Lecstor Logo" align="center" valign="center" padding="10" scale="60" />
        <column name="Header Right" grow="1" padding="10 10 10 0">
          <text name="Address1" padding="3" align="right" size="20">
            Lecstor Pty Ltd
          </text>
          <text name="Address2" padding="3" align="right" border_color="grey" size="14" color="black">
            ABN: 12 345 678 910
            123 Example St, Somewhere, Qld 4879
            (07) 4055 6926  jason@lecstor.com
          </text>
        </column>
      </row>
      <row name="Details" padding="15 0" border="0 0 1 0">
        <text name="Address" padding="20" size="14">
          Mr G Client
          Shop 2 Some Centre, Retail Rd
          Somewhere, NSW 2000
        </text>
        <column name="Invoice" padding="20" border_color="red" grow="1">
          <text name="IID" size="16" align="right" font="Helvetica-Bold">
            Tax Invoice No. 123
          </text>
          <text name="Issued" size="14" align="right">
            Issued 01/01/2011
          </text>
          <text name="Issued" size="14" align="right" font="Helvetica-Bold">
            Due 14/01/2011
          </text>
        </column>
      </row>
    </column>
    <grid name="ContentGrid" border="0 0 1 0">
      <row name="ItemHeader" font="Helvetica-Bold" padding="5" border="0" background="lightgrey">
        <text name="ItemHeaderName" align="center" padding="0 10">Name</text>
        <text name="ItemHeaderDesc" border_color="red" grow="1" align="center" padding="0 10">Description</text>
        <text name="ItemHeaderGST" padding="0 10" align="center">
          GST
          Amount
        </text>
        <text padding="0 10" align="center">
          Payable
          Amount
        </text>
      </row>
      <row grid="ContentGrid" name="ItemOne" margin="10 0 0 0" padding="0 5">
        <text padding="0 5">Web Services</text>
        <text name="ItemText2" grow="1" padding="0 5">
          a long description which needs to be wrapped in boxer markup source
        </text>
        <text padding="0 5" align="right">$9999.99</text>
        <text padding="0 5" align="right">$99999.99</text>
      </row>
      <row name="ItemTwo" margin="10 0 0 0" padding="0 5">
        <text padding="0 5">Web Services</text>
        <text grow="1" padding="0 5">
          a long description which needs to be a a a a a a a a a a a a a a a</text>
        <text padding="0 5" align="right">$9999.99</text>
        <text padding="0 5" align="right">$99999.99</text>
      </row>
    </grid>
    <column name="Footer" grow="1" border="1 0 0 0">
      <grid name="Totals" grow="1" padding="5">
        <row padding="5 0">
          <text grow="1" padding="0 10" align="right">Total Inc GST</text>
          <text padding="0 5" align="right">$9999999999.99</text>
        </row>
        <row padding="5 0">
          <text grow="1" padding="0 10" align="right">GST</text>
          <text padding="0 5" align="right">$999999999.99</text>
        </row>
        <row padding="5 0">
          <text grow="1" padding="0 10" align="right" font="Helvetica-Bold">Amount Due</text>
          <text padding="0 5" align="right">$9999999999.99</text>
        </row>
      </grid>
      <row name="DD">
        <column name="DirectDeposit" padding="10">
          <text name="DD1" size="18" font="Helvetica-Bold">
            Please pay by Direct Deposit:
          </text>
          <text name="DD2" size="16" padding="20">
            Commonwealth Bank, Cairns
            BSB: 01 2345
            Account: 1234 5678
          </text>
        </column>
      </row>
    </column>
  </column>

</doc>
__EOP__

my $parser = PDF::Boxer::SpecParser->new;
$spec = $parser->parse($spec);

my $boxer = PDF::Boxer->new( doc => { file => 'pdf_boxer_example.pdf' } );

$boxer->add_to_pdf($spec);

$boxer->finish;


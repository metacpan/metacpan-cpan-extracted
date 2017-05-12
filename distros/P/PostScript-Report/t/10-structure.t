#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 22 Oct 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the structure of the generated report
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;

# Load Test::Differences, if available:
BEGIN {
  # SUGGEST PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/10.structure.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 6;
}

require PostScript::Report;

my $code = '';

while (<DATA>) {

  print OUT $_ if $generateResults;

  if ($_ eq "<<'---'\n") {
    # Read the expected results:
    my $expected = '';
    while (<DATA>) {
      last if $_ eq "---\n";
      $expected .= $_;
    }

    # Run the test:
    my $param = eval $code;
    die $@ if $@;

    my $rpt = PostScript::Report->build($param);

    my $output = '';
    open (my $out, '>', \$output);
    select $out;
    print "BEFORE _init:\n";
    $rpt->dump;
    $rpt->_init;
    print "\nAFTER _init:\n";
    $rpt->dump;
    select STDOUT;
    $output =~ s/ +$//mg;       # Remove trailing space

    if ($generateResults) {
      print OUT "$output---\n";
    } else {
      # Split results into before & after:
      $output =~ s/\n(AFTER _init:\n.*)//s;
      my $outputA = $1;
      $expected =~ s/\n(AFTER _init:\n.*)//s;
      my $expectedA = $1;

      # And compare them:
      eq_or_diff($output,  $expected,  "$param->{title} before");
      eq_or_diff($outputA, $expectedA, "$param->{title} after");
    } # end else running tests

    # Clean up:
    $code = '';
  } # end if expected contents (<<'---' ... ---)
  else {
    $code .= $_;
  }
} # end while <DATA>

#=====================================================================

__DATA__

{
  title   => 'simple',
  columns => {
    data => [
      #                  Header is centered    Column is right justified
      [ 'Number' =>  40, { align => 'center'}, { align => 'right'} ],
      [ 'Letter' =>  40 ],
      [ 'Text'   => 320 ],
      #                  Both header and column are right justified
      [ 'Right'  =>  60, { align => 'right'}, { align => 'right'} ],
    ],
  }, # end columns
};
<<'---'
BEFORE _init:
align         : left
border        : 1
first_footer  : page
footer_align  : bottom
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
ps_parameters:
row_height    : 15
paper_size    : Letter
landscape     : 0
top_margin    : 72
bottom_margin : 72
left_margin   : 72
right_margin  : 72

page_header:
  PostScript::Report::HBox:
    children:
      PostScript::Report::Field:
        align         : center
        value         : PostScript::Report::Value::Constant
          value         : Number
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Letter
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Text
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : Right
        width         : 60

detail:
  PostScript::Report::HBox:
    children:
      PostScript::Report::Field:
        align         : right
        value         : 0
        width         : 40
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        value         : 2
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : 3
        width         : 60

AFTER _init:
align         : left
border        : 1
first_footer  : page
footer_align  : bottom
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
ps_parameters:
row_height    : 15
paper_size    : Letter
landscape     : 0
top_margin    : 72
bottom_margin : 72
left_margin   : 72
right_margin  : 72

page_header:
  PostScript::Report::HBox:
    height        : 15
    width         : 460
    children:
      PostScript::Report::Field:
        align         : center
        value         : PostScript::Report::Value::Constant
          value         : Number
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Letter
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Text
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : Right
        width         : 60

detail:
  PostScript::Report::HBox:
    height        : 15
    width         : 460
    children:
      PostScript::Report::Field:
        align         : right
        value         : 0
        width         : 40
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        value         : 2
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : 3
        width         : 60
---

{
  title => 'simple with header',
  report_header => [ HBox => { border => 0 },
    { _class => 'Spacer',
      height => 64,
      width  => 64 },
    [ VBox => { width => 100 },
      { value => \'Foo Bar Recycling' },
      { value => \'123 Any Street' },
      { value => \'Your Town, USA' },
    ],
  ], # end report_header

  columns => {
    header => { background => '#abc' },
    data => [
      [ 'Number' =>  40, { align => 'center'}, { align => 'right'} ],
      [ 'Letter' =>  40 ],
      [ 'Text'   => 320 ],
      [ 'Right'  =>  60, { align => 'right'}, { align => 'right'} ],
    ],
  }, # end columns
};
<<'---'
BEFORE _init:
align         : left
border        : 1
first_footer  : page
footer_align  : bottom
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
ps_parameters:
row_height    : 15
paper_size    : Letter
landscape     : 0
top_margin    : 72
bottom_margin : 72
left_margin   : 72
right_margin  : 72

report_header:
  PostScript::Report::HBox:
    border        : 0
    children:
      PostScript::Report::Spacer:
        height        : 64
        width         : 64
      PostScript::Report::VBox:
        width         : 100
        children:
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : Foo Bar Recycling
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : 123 Any Street
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : Your Town, USA

page_header:
  PostScript::Report::HBox:
    background    : #AABBCC
    children:
      PostScript::Report::Field:
        align         : center
        value         : PostScript::Report::Value::Constant
          value         : Number
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Letter
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Text
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : Right
        width         : 60

detail:
  PostScript::Report::HBox:
    children:
      PostScript::Report::Field:
        align         : right
        value         : 0
        width         : 40
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        value         : 2
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : 3
        width         : 60

AFTER _init:
align         : left
border        : 1
first_footer  : page
footer_align  : bottom
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
ps_parameters:
row_height    : 15
paper_size    : Letter
landscape     : 0
top_margin    : 72
bottom_margin : 72
left_margin   : 72
right_margin  : 72

report_header:
  PostScript::Report::HBox:
    border        : 0
    height        : 64
    width         : 164
    children:
      PostScript::Report::Spacer:
        height        : 64
        width         : 64
      PostScript::Report::VBox:
        height        : 45
        width         : 100
        children:
          PostScript::Report::Field:
            height        : 15
            value         : PostScript::Report::Value::Constant
              value         : Foo Bar Recycling
          PostScript::Report::Field:
            height        : 15
            value         : PostScript::Report::Value::Constant
              value         : 123 Any Street
          PostScript::Report::Field:
            height        : 15
            value         : PostScript::Report::Value::Constant
              value         : Your Town, USA

page_header:
  PostScript::Report::HBox:
    background    : #AABBCC
    height        : 15
    width         : 460
    children:
      PostScript::Report::Field:
        align         : center
        value         : PostScript::Report::Value::Constant
          value         : Number
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Letter
        width         : 40
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : Text
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : Right
        width         : 60

detail:
  PostScript::Report::HBox:
    height        : 15
    width         : 460
    children:
      PostScript::Report::Field:
        align         : right
        value         : 0
        width         : 40
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        value         : 2
        width         : 320
      PostScript::Report::Field:
        align         : right
        value         : 3
        width         : 60
---


{
  title => 'multiline header',
  fonts => {
    label     => 'Helvetica-6',
    text      => 'Helvetica-9',
    boldText  => 'Helvetica-Bold-9',
    pageNum   => 'Helvetica-8',
    bottomRow => 'Helvetica-6',
    disclaimerText => 'Helvetica-Bold-8',
  },

  font       => 'text',
  label_font => 'label',
  align      => 'center',

  padding_bottom => 4,
  padding_side   => 3,

  landscape     => 1,
  top_margin    => 25,
  left_margin   => 20,
  right_margin  => 20,
  bottom_margin => 25,
  row_height    => 22,

  default_field_type => 'FieldTL',

  # The report_header is one line with text fields left, center, & right.
  # All values are constant.
  report_header => [
    HBox => { border => 0,
              font => 'boldText',
              height => 12,
              padding_side   => 0,
              _default => 'Field',
            },
    { width  => 200,
      align  => 'left',
      value  => \'AIRPLANE COMPONENT FIXING INC.' },
    { width  => 351,
      value  => \'WORK ORDER' },
    { width  => 200,
      align  => 'right',
      value  => \'F.A.A REPAIR STATION NO. L3PF428Q' },
  ],

  # The page_header is fairly complex.
  # The Material Type field spans rows 2 and 3.
  page_header => [
    # This HBox is row 1 of the header:
    [ { label => 'Customer Name:',
        value => 'custName',
        width => 160 },
      { label => 'Part Number Received:',
        value => 'partNumReceived',
        width => 146 },
      { label => 'Serial Number Received:',
        value => 'serialNumReceived',
        width => 156 },
      { label => 'Installed On:',
        value => 'installedOn',
        align => 'left',
        width => 130 },
      { label => 'Location:',
        value => 'location',
        width => 54 },
      { label => 'Work Order#:',
        value => 'workOrder',
        font  => 'boldText',
        width => 105 },
    ],
    # This HBox contains rows 2 & 3, because Material Type is 2 rows high:
    [
      # This VBox is the left hand side of rows 2 & 3:
      [
        # This HBox is the left hand side of row 2:
        [ { label => 'Part Description:',
            value => 'partDesc',
            width => 160 },
          { label => 'Part Number Returned:',
            value => 'partNumReturned',
            width => 146 },
          { label => 'Serial Number Returned:',
            value => 'serialNumReturned',
            width => 156 },
        ], # end row 2 left
        # This HBox is the left hand side of row 3:
        [ { label => 'Date Received:',
            value => 'dateReceived',
            width => 69 },
          { label => 'RO Due Date:',
            value => 'roDueDate',
            width => 91 },
          { label => 'Repair/Overhaul Per:',
            value => 'repairPer',
            align => 'left',
            width => 302 },
        ] ], # end rows 2 & 3 left
      # This field is two rows high:
      { label => 'Material Type:',
        value => 'materialType',
        align => 'left',
        height    => 44,
        multiline => 1,
        width => 130 },
      # This VBox is the right hand side of rows 2 & 3:
      [
        # Don't need an HBox for row 2 right; it's only one field:
        { label => 'Customer Order Number:',
          value => 'custOrderNum',
          width => 159 },
        # This HBox is the right hand side of row 3:
        [ { label => 'Part Verified By:',
            value => 'verifiedBy',
            width => 80 },
          { label => 'Revised Due Date:',
            value => 'revisedDueDate',
            width => 79 },
        ] ], # end rows 2 & 3 right
    ], # end rows 2 & 3
  ], # end page_header

  columns => {
    header => {
      font           => 'boldText',
      height         => 19,
      padding_bottom => 6,
    },
    detail => {
      height         => 19,
      padding_bottom => 6,
    },
    data => [
      [ 'SEQ#' => 29 ],
      [ 'STA#' => 40 ],
      [ 'REPAIR SCOPE' => 450, { align => 'left'}, { align => 'left'} ],
      [ MECHANIC => 73 ],
      [ INSPECTOR => 80 ],
      # The DATE column is filled in by hand after printing.  We'll
      # use a Spacer in the detail section so we don't need a blank
      # column in each row.  (Note: If this weren't the last column,
      # we'd also need to pass a fake value to the Spacer to tell the
      # builder not to increment the column number.)
      [ DATE => 79, undef, { _class => 'Spacer' } ],
    ],
  }, # end columns

  # The footer is also a bit complex:
  page_footer => [
    # We don't want a border around the whole footer:
    VBox => { border => 0 },
    # The first row is just one component:
    { _class => 'Field',
      font   => 'disclaimerText',
      value  => \'The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.',
    },
    # The second row is filled in by hand, so the values are blank:
    [ HBox => { border => 1 },
      { label => 'Inspector',
        value => \'',
        width => 339 },
      { label => 'Final Inspection Stamp',
        value => \'',
        width => 154 },
      { label => 'Date',
        value => \'',
        width => 258 },
    ],
    # The third row includes the page number and checkboxes:
    [ HBox => {
        border => 1,
        height => 14,
        font => 'bottomRow',
        padding_side => 0,
        _default => 'Field',
      },
      # This HBox exists just to set parameters on its children:
      [ HBox => { border => 0, font  => 'pageNum' },
        { value => \'42410-1',
          width => 57 },
        { _class => 'Spacer',
          width  => 14 },
        { align => 'left',
          value => { _class => 'Page', value => 'Page(s): %n OF %t' },
          width => 377 },
      ],
      # This HBox exists just to set parameters on its children:
      [ HBox => { border => 0, padding_bottom => 6, padding_side => 2 },
        { align => 'right',
          value => \'ML',
          width => 10 },
        { align => 'right',
          value => \'FXN-',
          width => 53 },
        { align => 'left',
          value => 'FXN',
          width => 28 },
        { align => 'right',
          value => \'AP',
          width => 17 },
        { _class => 'Checkbox',
          value => 'AP',
          padding_bottom => 3,
          width => 20 },
        { align => 'right',
          value => \'BP',
          width => 20 },
        { _class => 'Checkbox',
          value => 'BP',
          padding_bottom => 3,
          width => 20 },
        { align => 'right',
          value => \'Photo',
          width => 45 },
        { align => 'left',
          value => 'photo',
          width => 28 },
        { align => 'right',
          value => \'QTY',
          width => 35 },
        { align => 'left',
          value => 'qty',
          width => 27 },
      ],
    ], # end third row of page_footer
  ], # end page_footer
};
<<'---'
BEFORE _init:
align         : center
border        : 1
extra_styles:
  label_font    : Helvetica-iso 6
first_footer  : page
font          : Helvetica-iso 9
footer_align  : bottom
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
ps_parameters:
row_height    : 22
paper_size    : Letter
landscape     : 1
top_margin    : 25
bottom_margin : 25
left_margin   : 20
right_margin  : 20

report_header:
  PostScript::Report::HBox:
    border        : 0
    font          : Helvetica-Bold-iso 9
    height        : 12
    padding_side  : 0
    children:
      PostScript::Report::Field:
        align         : left
        value         : PostScript::Report::Value::Constant
          value         : AIRPLANE COMPONENT FIXING INC.
        width         : 200
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : WORK ORDER
        width         : 351
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : F.A.A REPAIR STATION NO. L3PF428Q
        width         : 200

page_header:
  PostScript::Report::VBox:
    children:
      PostScript::Report::HBox:
        children:
          PostScript::Report::FieldTL:
            label         : Customer Name:
            value         : custName
            width         : 160
          PostScript::Report::FieldTL:
            label         : Part Number Received:
            value         : partNumReceived
            width         : 146
          PostScript::Report::FieldTL:
            label         : Serial Number Received:
            value         : serialNumReceived
            width         : 156
          PostScript::Report::FieldTL:
            align         : left
            label         : Installed On:
            value         : installedOn
            width         : 130
          PostScript::Report::FieldTL:
            label         : Location:
            value         : location
            width         : 54
          PostScript::Report::FieldTL:
            font          : Helvetica-Bold-iso 9
            label         : Work Order#:
            value         : workOrder
            width         : 105
      PostScript::Report::HBox:
        children:
          PostScript::Report::VBox:
            children:
              PostScript::Report::HBox:
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Description:
                    value         : partDesc
                    width         : 160
                  PostScript::Report::FieldTL:
                    label         : Part Number Returned:
                    value         : partNumReturned
                    width         : 146
                  PostScript::Report::FieldTL:
                    label         : Serial Number Returned:
                    value         : serialNumReturned
                    width         : 156
              PostScript::Report::HBox:
                children:
                  PostScript::Report::FieldTL:
                    label         : Date Received:
                    value         : dateReceived
                    width         : 69
                  PostScript::Report::FieldTL:
                    label         : RO Due Date:
                    value         : roDueDate
                    width         : 91
                  PostScript::Report::FieldTL:
                    align         : left
                    label         : Repair/Overhaul Per:
                    value         : repairPer
                    width         : 302
          PostScript::Report::FieldTL:
            align         : left
            height        : 44
            label         : Material Type:
            multiline     : 1
            value         : materialType
            width         : 130
          PostScript::Report::VBox:
            children:
              PostScript::Report::FieldTL:
                label         : Customer Order Number:
                value         : custOrderNum
                width         : 159
              PostScript::Report::HBox:
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Verified By:
                    value         : verifiedBy
                    width         : 80
                  PostScript::Report::FieldTL:
                    label         : Revised Due Date:
                    value         : revisedDueDate
                    width         : 79
      PostScript::Report::HBox:
        font          : Helvetica-Bold-iso 9
        height        : 19
        padding_bottom: 6
        children:
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : SEQ#
            width         : 29
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : STA#
            width         : 40
          PostScript::Report::Field:
            align         : left
            value         : PostScript::Report::Value::Constant
              value         : REPAIR SCOPE
            width         : 450
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : MECHANIC
            width         : 73
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : INSPECTOR
            width         : 80
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : DATE
            width         : 79

detail:
  PostScript::Report::HBox:
    height        : 19
    padding_bottom: 6
    children:
      PostScript::Report::Field:
        value         : 0
        width         : 29
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        align         : left
        value         : 2
        width         : 450
      PostScript::Report::Field:
        value         : 3
        width         : 73
      PostScript::Report::Field:
        value         : 4
        width         : 80
      PostScript::Report::Spacer:
        width         : 79

page_footer:
  PostScript::Report::VBox:
    border        : 0
    children:
      PostScript::Report::Field:
        font          : Helvetica-Bold-iso 8
        value         : PostScript::Report::Value::Constant
          value         : The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.
      PostScript::Report::HBox:
        border        : 1
        children:
          PostScript::Report::FieldTL:
            label         : Inspector
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 339
          PostScript::Report::FieldTL:
            label         : Final Inspection Stamp
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 154
          PostScript::Report::FieldTL:
            label         : Date
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 258
      PostScript::Report::HBox:
        border        : 1
        font          : Helvetica-iso 6
        height        : 14
        padding_side  : 0
        children:
          PostScript::Report::HBox:
            border        : 0
            font          : Helvetica-iso 8
            children:
              PostScript::Report::Field:
                value         : PostScript::Report::Value::Constant
                  value         : 42410-1
                width         : 57
              PostScript::Report::Spacer:
                width         : 14
              PostScript::Report::Field:
                align         : left
                value         : PostScript::Report::Value::Page
                  value         : Page(s): %n OF %t
                width         : 377
          PostScript::Report::HBox:
            border        : 0
            padding_bottom: 6
            padding_side  : 2
            children:
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : ML
                width         : 10
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : FXN-
                width         : 53
              PostScript::Report::Field:
                align         : left
                value         : FXN
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : AP
                width         : 17
              PostScript::Report::Checkbox:
                padding_bottom: 3
                value         : AP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : BP
                width         : 20
              PostScript::Report::Checkbox:
                padding_bottom: 3
                value         : BP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : Photo
                width         : 45
              PostScript::Report::Field:
                align         : left
                value         : photo
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : QTY
                width         : 35
              PostScript::Report::Field:
                align         : left
                value         : qty
                width         : 27

AFTER _init:
align         : center
border        : 1
extra_styles:
  label_font    : Helvetica-iso 6
first_footer  : page
font          : Helvetica-iso 9
footer_align  : bottom
line_width    : 0.5
padding_bottom: 4
padding_side  : 3
ps_parameters:
row_height    : 22
paper_size    : Letter
landscape     : 1
top_margin    : 25
bottom_margin : 25
left_margin   : 20
right_margin  : 20

report_header:
  PostScript::Report::HBox:
    border        : 0
    font          : Helvetica-Bold-iso 9
    height        : 12
    padding_side  : 0
    width         : 751
    children:
      PostScript::Report::Field:
        align         : left
        value         : PostScript::Report::Value::Constant
          value         : AIRPLANE COMPONENT FIXING INC.
        width         : 200
      PostScript::Report::Field:
        value         : PostScript::Report::Value::Constant
          value         : WORK ORDER
        width         : 351
      PostScript::Report::Field:
        align         : right
        value         : PostScript::Report::Value::Constant
          value         : F.A.A REPAIR STATION NO. L3PF428Q
        width         : 200

page_header:
  PostScript::Report::VBox:
    height        : 85
    width         : 751
    children:
      PostScript::Report::HBox:
        height        : 22
        width         : 751
        children:
          PostScript::Report::FieldTL:
            label         : Customer Name:
            value         : custName
            width         : 160
          PostScript::Report::FieldTL:
            label         : Part Number Received:
            value         : partNumReceived
            width         : 146
          PostScript::Report::FieldTL:
            label         : Serial Number Received:
            value         : serialNumReceived
            width         : 156
          PostScript::Report::FieldTL:
            align         : left
            label         : Installed On:
            value         : installedOn
            width         : 130
          PostScript::Report::FieldTL:
            label         : Location:
            value         : location
            width         : 54
          PostScript::Report::FieldTL:
            font          : Helvetica-Bold-iso 9
            label         : Work Order#:
            value         : workOrder
            width         : 105
      PostScript::Report::HBox:
        height        : 44
        width         : 751
        children:
          PostScript::Report::VBox:
            height        : 44
            width         : 462
            children:
              PostScript::Report::HBox:
                height        : 22
                width         : 462
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Description:
                    value         : partDesc
                    width         : 160
                  PostScript::Report::FieldTL:
                    label         : Part Number Returned:
                    value         : partNumReturned
                    width         : 146
                  PostScript::Report::FieldTL:
                    label         : Serial Number Returned:
                    value         : serialNumReturned
                    width         : 156
              PostScript::Report::HBox:
                height        : 22
                width         : 462
                children:
                  PostScript::Report::FieldTL:
                    label         : Date Received:
                    value         : dateReceived
                    width         : 69
                  PostScript::Report::FieldTL:
                    label         : RO Due Date:
                    value         : roDueDate
                    width         : 91
                  PostScript::Report::FieldTL:
                    align         : left
                    label         : Repair/Overhaul Per:
                    value         : repairPer
                    width         : 302
          PostScript::Report::FieldTL:
            align         : left
            height        : 44
            label         : Material Type:
            multiline     : 1
            value         : materialType
            width         : 130
          PostScript::Report::VBox:
            height        : 44
            width         : 159
            children:
              PostScript::Report::FieldTL:
                height        : 22
                label         : Customer Order Number:
                value         : custOrderNum
                width         : 159
              PostScript::Report::HBox:
                height        : 22
                width         : 159
                children:
                  PostScript::Report::FieldTL:
                    label         : Part Verified By:
                    value         : verifiedBy
                    width         : 80
                  PostScript::Report::FieldTL:
                    label         : Revised Due Date:
                    value         : revisedDueDate
                    width         : 79
      PostScript::Report::HBox:
        font          : Helvetica-Bold-iso 9
        height        : 19
        padding_bottom: 6
        width         : 751
        children:
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : SEQ#
            width         : 29
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : STA#
            width         : 40
          PostScript::Report::Field:
            align         : left
            value         : PostScript::Report::Value::Constant
              value         : REPAIR SCOPE
            width         : 450
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : MECHANIC
            width         : 73
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : INSPECTOR
            width         : 80
          PostScript::Report::Field:
            value         : PostScript::Report::Value::Constant
              value         : DATE
            width         : 79

detail:
  PostScript::Report::HBox:
    height        : 19
    padding_bottom: 6
    width         : 751
    children:
      PostScript::Report::Field:
        value         : 0
        width         : 29
      PostScript::Report::Field:
        value         : 1
        width         : 40
      PostScript::Report::Field:
        align         : left
        value         : 2
        width         : 450
      PostScript::Report::Field:
        value         : 3
        width         : 73
      PostScript::Report::Field:
        value         : 4
        width         : 80
      PostScript::Report::Spacer:
        width         : 79

page_footer:
  PostScript::Report::VBox:
    border        : 0
    height        : 58
    width         : 751
    children:
      PostScript::Report::Field:
        font          : Helvetica-Bold-iso 8
        height        : 22
        value         : PostScript::Report::Value::Constant
          value         : The component identified above was repaired/overhauled/inspected IAW current federal aviation regulations and in respect to that work, was found airworthy for return to service.
      PostScript::Report::HBox:
        border        : 1
        height        : 22
        width         : 751
        children:
          PostScript::Report::FieldTL:
            label         : Inspector
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 339
          PostScript::Report::FieldTL:
            label         : Final Inspection Stamp
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 154
          PostScript::Report::FieldTL:
            label         : Date
            value         : PostScript::Report::Value::Constant
              value         :
            width         : 258
      PostScript::Report::HBox:
        border        : 1
        font          : Helvetica-iso 6
        height        : 14
        padding_side  : 0
        width         : 751
        children:
          PostScript::Report::HBox:
            border        : 0
            font          : Helvetica-iso 8
            width         : 448
            children:
              PostScript::Report::Field:
                value         : PostScript::Report::Value::Constant
                  value         : 42410-1
                width         : 57
              PostScript::Report::Spacer:
                width         : 14
              PostScript::Report::Field:
                align         : left
                value         : PostScript::Report::Value::Page
                  value         : Page(s): %n OF %t
                width         : 377
          PostScript::Report::HBox:
            border        : 0
            padding_bottom: 6
            padding_side  : 2
            width         : 303
            children:
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : ML
                width         : 10
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : FXN-
                width         : 53
              PostScript::Report::Field:
                align         : left
                value         : FXN
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : AP
                width         : 17
              PostScript::Report::Checkbox:
                padding_bottom: 3
                value         : AP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : BP
                width         : 20
              PostScript::Report::Checkbox:
                padding_bottom: 3
                value         : BP
                width         : 20
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : Photo
                width         : 45
              PostScript::Report::Field:
                align         : left
                value         : photo
                width         : 28
              PostScript::Report::Field:
                align         : right
                value         : PostScript::Report::Value::Constant
                  value         : QTY
                width         : 35
              PostScript::Report::Field:
                align         : left
                value         : qty
                width         : 27
---

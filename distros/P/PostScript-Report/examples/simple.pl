#! /usr/bin/perl
#---------------------------------------------------------------------
# This example report is hereby placed in the public domain.
# You may copy from it freely.
#
# This is a simple example for PostScript::Report.
#---------------------------------------------------------------------

use strict;
use warnings;

use PostScript::Report ();

# Describe the report:
my $desc = {
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

# Generate sample data for the report:
my $letter = 'A';

my @rows = map { my $r=[ $_, $letter, "$_ $letter", "Right $_" ];
                 ++$letter;
                 $r } 1 .. 80;

# Build the report and run it:
my $rpt = PostScript::Report->build($desc);

$rpt->run(\@rows)->output("simple.ps");

# $rpt->dump;

#! /usr/bin/perl
#---------------------------------------------------------------------
# This example report is hereby placed in the public domain.
# You may copy from it freely.
#
# This shows all the possible border styles for PostScript::Report.
#---------------------------------------------------------------------

use strict;
use warnings;

use PostScript::Report ();

my @borderTest = qw(width 40  background 0.875  border);

my $spacer = { height => 10, width => 10 };

# Describe the report:
my $desc = {
  default_field_type => 'Spacer',

  border     => 0,
  line_width => 2,

  report_header => [
    [ { @borderTest => 'T' },
      $spacer,
      { @borderTest => 'B' },
      $spacer,
      { @borderTest => 'L' },
      $spacer,
      { @borderTest => 'R' },
      $spacer,
      { @borderTest => '0' },
      $spacer,
      { @borderTest => 'TB' },
      $spacer,
      { @borderTest => 'LR' },
      $spacer,
      { @borderTest => 'TLR' },
      $spacer,
    ],
    $spacer,
    [ { @borderTest => 'TL' },
      $spacer,
      { @borderTest => 'TR' },
      $spacer,
      { @borderTest => 'BL' },
      $spacer,
      { @borderTest => 'BR' },
      $spacer,
      { @borderTest => '1' },
      $spacer,
      { @borderTest => 'TBL' },
      $spacer,
      { @borderTest => 'TBR' },
      $spacer,
      { @borderTest => 'BLR' },
      $spacer,
    ],
  ], # end report_header
};

# Build the report and run it:
my $rpt = PostScript::Report->build($desc);

$rpt->run->output("border_test.ps");

#$rpt->dump;

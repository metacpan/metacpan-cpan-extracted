#! /usr/bin/perl
#---------------------------------------------------------------------
# The SYNOPSIS example of PostScript::ScheduleGrid::XMLTV
# by Christopher J. Madsen
#
# This example script is in the public domain.
# Copy from it as you like.
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.010;

use DateTime ();
use PostScript::ScheduleGrid::XMLTV ();

my $start_date = DateTime->today(time_zone => 'local');
my $end_date   = $start_date->clone->add(days => 3);

my $tv = PostScript::ScheduleGrid::XMLTV->new(
  start_date => $start_date,  end_date => $end_date,
);

my $grid = $tv->parsefiles('data.xml')->grid;

$grid->output('listings.ps');

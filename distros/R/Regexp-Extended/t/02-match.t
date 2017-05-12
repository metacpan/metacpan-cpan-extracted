#!/usr/bin/perl -w

use Test;
use Data::Dumper;
use Clone qw(clone);
use strict;

BEGIN { plan tests => 1 }

use Regexp::Extended qw(:all);
use re 'eval';

my $p_day   = qr/(?<day>\d{1,2})/;
my $p_month = qr/(?<month>\d{1,2})/;
my $p_year  = qr/(?<year>\d{4})/;
my $p_date  = qr/(?<date>$p_day-$p_month-$p_year)/;

my $dates = "1-2-2003 3-4-2004 5-10-2005 6-12-2006    ";

($::day, $::date) = undef;

if ($dates =~ /\A$p_date(?:\s$p_date)*\s$p_date\Z/) {
  $::day->[1]  = "1000";
  $::date->[0] = "12-12-2005";

  ok(rebuild($dates), "12-12-2005 1000-4-2004 5-10-2005 6-12-2006    "); 
}

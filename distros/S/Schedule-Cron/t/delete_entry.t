#!/usr/bin/perl
#

# =============================================
# Adapted from patch provided with RT #54692

use Test::More tests => 3;

use Schedule::Cron;
use Data::Dumper;
use strict;
use warnings;

$| = 1;

#System::Proc::Simple->debug(0);

my $cron = new Schedule::Cron(
                              \&dispatcher,
                              nofork => 1,
                              catch => 0,
                             );

$cron->add_entry("* * * * * *", 'Test1');
$cron->add_entry("* * * * * *", 'Test2');

my $e_idx = $cron->check_entry('Test2');
$cron->delete_entry($e_idx);

$cron->add_entry("* * * * * *", 'Test3');

foreach my $e_name (qw/Test1 Test2 Test3/) {
  my $e_idx = $cron->check_entry($e_name);
  if (defined($e_idx)) {
    my $entry = $cron->get_entry($e_idx);
    is($entry->{args}->[0],$e_name,"$e_name defined");
  }
  else {
      is($e_name,"Test2","Test2 not found");
  }
}

sub dispatcher {
  my $name = shift;
  printf "Running %s.\n", $name;
}

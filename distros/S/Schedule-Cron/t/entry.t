#!/usr/bin/perl
#
# Test management methods for adding/deleting/updating entries
use Test::More tests => 19;

use Schedule::Cron;
use Data::Dumper;
use strict;

my $dispatcher = sub { print "Dispatcher\n"};
my $special_dispatch = sub { print "Special Dispatcher\n"};
my $cron = new Schedule::Cron($dispatcher);

eval
{
    $cron->add_entry("*");
};
ok($@," invalid add arguments: $@");

eval
{
    $cron->add_entry("* * * * *",{'subroutine' => \&dispatch,
                                  'arguments'  => [ "first",2,"third" ],
                                  'eval'       => 1});
};
ok($@," invalid add arguments: $@");

# get
my $timespec = "5 * * * *";
$cron->add_entry($timespec,"doit");
ok (scalar($cron->list_entries()) == 1,"3 list entries");
my $entry = $cron->get_entry(0);
ok ($entry->{time} eq $timespec,"entry 0 timespec");
ok ($entry->{dispatcher} eq $dispatcher,"entry 0 dispatcher");
ok ($entry->{args}->[0] eq "doit","entry 0 args");
ok (!defined($cron->get_entry(2)),"entry: invalid index");

# Add two extras
$cron->add_entry($timespec,$special_dispatch);
my $timespec3 = "* * * * * */2";
$cron->add_entry($timespec3,"yet","some","arguments");

ok (scalar($cron->list_entries()) == 3,"3 list entries");
ok ($cron->get_entry(1)->{dispatcher} eq $special_dispatch,"entry 1 dispatcher");
my $args_2 = [ 10,12,13 ];
my $timespec_2 = "12 13 7 7 *";
my $old_entry = $cron->update_entry(1,{time => $timespec_2,args => $args_2});

# Update
ok ($old_entry->{time} eq $timespec && $old_entry->{dispatcher} == $special_dispatch 
    && @{$old_entry->{args}} == 0,
    "update: old entry");
$entry = $cron->get_entry(1);
ok ($entry->{time} eq $timespec_2 && $entry->{dispatcher} eq $dispatcher,
   "update: new entry");
ok ($entry->{args} != $args_2,"update: deep copy");
ok (scalar(grep { $args_2->[$_] == $entry->{args}->[$_] } (0,1,2)) == 3,"update: deep copy 2");

# Delete
$old_entry = $cron->delete_entry(1);
ok ($old_entry->{time} eq $timespec_2 && $entry->{dispatcher} eq $dispatcher,"delete: old entry");
ok (scalar($cron->list_entries) == 2,"delete: nr. entries");
$entry = $cron->get_entry(1);
ok ($entry->{time} eq $timespec3 && $entry->{dispatcher} == $dispatcher &&
   $entry->{args}->[1] eq "some","delete: splicing");
$old_entry = $cron->delete_entry(0);
ok ($old_entry->{time} eq $timespec && $entry->{dispatcher} eq $dispatcher,"delete: old entry (2)");
ok (scalar($cron->list_entries) == 1,"delete: nr. entries");

# Clean all
$cron->clean_timetable;
ok (scalar($cron->list_entries) == 0,"clean");

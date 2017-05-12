#!/usr/local/bin/perl
use strict;

use SysAdmin::Date;

my $object = new SysAdmin::Date();

my $epoch = $object->epoch;
my $today = $object->today;

print "Epoch $epoch\n";
print "Today $today\n";

my $new_object = new SysAdmin::Date(format => "%Y-%m-%d %T");

my $formatted_date = $new_object->date;

print "User formatted Date $formatted_date\n";

my $another_object = new SysAdmin::Date(offset => "86400");

my $offset_date = $another_object->date;

print "Offset Date $offset_date\n";


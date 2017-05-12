#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC;

# Object.
my $obj = Person::ID::CZ::RC->new(
        'rc' => '840229|1330',
);

# Get error.
my $error = $obj->error || '-';

# Print out.
print "Personal number: ".$obj->rc."\n";
print "Year: ".$obj->year."\n";
print "Month: ".$obj->month."\n";
print "Day: ".$obj->day."\n";
print "Sex: ".$obj->sex."\n";
print "Serial: ".$obj->serial."\n";
print "Checksum: ".$obj->checksum."\n";
print "Alternate: ".$obj->alternate."\n";
print "Valid: ".$obj->is_valid."\n";
print "Error: ".$error."\n";

# Output:
# Personal number: 840229|1330
# Year: -
# Month: -
# Day: -
# Sex: -
# Serial: -
# Checksum: -
# Alternate: -
# Valid: 0
# Error: Format of rc identification isn't valid.
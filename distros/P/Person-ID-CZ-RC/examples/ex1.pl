#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC;

# Object.
my $obj = Person::ID::CZ::RC->new(
        'rc' => '840501/1330',
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
# Personal number: 840501/1330
# Year: 1984
# Month: 05
# Day: 01
# Sex: male
# Serial: 133
# Checksum: 0
# Alternate: 0
# Valid: 1
# Error: -
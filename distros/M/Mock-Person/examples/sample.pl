#!/usr/bin/perl

use strict;
use warnings;

use Mock::Person;
binmode STDOUT, ":utf8";

for (my $i = 0; $i<30; $i++) {
    print Mock::Person::name(sex => "female") . "\n";
};

#!/usr/bin/env perl

use strict;
use warnings;

use Person::ID::CZ::RC::Generator;

# Object.
my $obj = Person::ID::CZ::RC::Generator->new(
        'day' => 1,
        'month' => 5,
        'rc_sep' => '/',
        'serial' => 133,
        'sex' => 'male',
        'year' => 1984,
);

# Print out.
print "Personal number: ".$obj->rc."\n";

# Output:
# Personal number: 840501/1330
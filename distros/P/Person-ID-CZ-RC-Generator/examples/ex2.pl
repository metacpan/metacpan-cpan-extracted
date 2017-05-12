#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Person::ID::CZ::RC::Generator;

# Object.
my $obj = Person::ID::CZ::RC::Generator->new(
        'day' => 1,
        'month' => 5,
        'rc_sep' => '/',
        'serial' => 133,
        'sex' => 'male',
        'year' => 1952,
);

# Print out.
print "Personal number: ".$obj->rc."\n";

# Output:
# Personal number: 520501/133
#!/usr/bin/env perl

use strict;
use warnings;

use Person::ID::CZ::RC::Generator;

# Object.
my $obj = Person::ID::CZ::RC::Generator->new(
        'rc_sep' => '/',
);

# Print out.
print "Personal number: ".$obj->rc."\n";

# Output like:
# Personal number: qr{\d\d\d\d\d\d\/\d\d\d\d?}
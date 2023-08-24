#!/usr/bin/env perl

use strict;
use warnings;

use Random::Set;

# Object.
my $obj = Random::Set->new(
        'set' => [
                [0.1, 'foo'],
                [0.9, 'bar'],
        ],
);

# Get random data.
my $random = $obj->get;

# Print out.
print $random."\n";

# Output like:
# foo (10%)|bar (90%)
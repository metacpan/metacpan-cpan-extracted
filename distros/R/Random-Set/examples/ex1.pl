#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Random::Set;

# Object.
my $obj = Random::Set->new(
        'set' => [
                [0.5, 'foo'],
                [0.5, 'bar'],
        ],
);

# Get random data.
my $random = $obj->get;

# Print out.
print $random."\n";

# Output like:
# foo|bar
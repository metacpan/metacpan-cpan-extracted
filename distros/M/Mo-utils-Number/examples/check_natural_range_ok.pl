#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number::Range qw(check_natural_range);

my $self = {
        'key' => 0,
};
check_natural_range($self, 'key', -1, 1);

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number::Range qw(check_positive_natural_range);

my $self = {
        'key' => '10',
};
check_positive_natural_range($self, 'key', 1.1, 11);

# Print out.
print "ok\n";

# Output:
# ok
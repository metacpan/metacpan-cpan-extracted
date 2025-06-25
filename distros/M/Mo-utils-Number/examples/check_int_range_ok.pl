#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number::Range qw(check_int_range);

my $self = {
        'key' => -2,
};
check_int_range($self, 'key', -3, -1);

# Print out.
print "ok\n";

# Output:
# ok
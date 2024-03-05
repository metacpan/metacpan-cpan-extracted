#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_number_range);

my $self = {
        'key' => '10',
};
check_number_range($self, 'key', 1, 10);

# Print out.
print "ok\n";

# Output:
# ok
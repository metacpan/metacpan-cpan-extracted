#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_number_min);

my $self = {
        'key' => 10,
};
check_number_min($self, 'key', 5);

# Print out.
print "ok\n";

# Output:
# ok
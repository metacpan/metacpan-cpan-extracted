#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_angle);

my $self = {
        'key' => 10.1,
};
check_angle($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number qw(check_natural);

my $self = {
        'key' => 0,
};
check_natural($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
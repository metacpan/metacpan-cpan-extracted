#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number qw(check_positive_natural);

my $self = {
        'key' => '3',
};
check_positive_natural($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
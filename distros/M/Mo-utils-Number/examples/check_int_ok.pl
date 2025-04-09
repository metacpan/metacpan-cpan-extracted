#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number qw(check_int);

my $self = {
        'key' => -2,
};
check_int($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
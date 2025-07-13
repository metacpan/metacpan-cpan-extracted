#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number qw(check_positive_decimal);

my $self = {
        'key' => 3.2,
};
check_positive_decimal($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
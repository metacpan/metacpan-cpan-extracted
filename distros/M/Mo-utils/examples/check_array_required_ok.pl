#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_array_required);

my $self = {
        'key' => ['value'],
};
check_array_required($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
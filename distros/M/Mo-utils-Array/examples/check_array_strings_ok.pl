#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Array qw(check_array_strings);

my $self = {
        'key' => ['value'],
};
check_array_strings($self, 'key', ['value']);

# Print out.
print "ok\n";

# Output:
# ok
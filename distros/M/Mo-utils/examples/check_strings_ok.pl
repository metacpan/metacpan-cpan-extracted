#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_strings);

my $self = {
        'key' => 'value',
};
check_strings($self, 'key', ['value', 'foo']);

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_string);

my $self = {
        'key' => 'foo',
};
check_string($self, 'key', 'foo');

# Print out.
print "ok\n";

# Output:
# ok
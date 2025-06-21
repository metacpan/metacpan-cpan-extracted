#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Hash qw(check_hash);

my $self = {
        'key' => {},
};
check_hash($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
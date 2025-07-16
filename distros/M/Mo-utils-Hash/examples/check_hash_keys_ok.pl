#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Hash 0.02 qw(check_hash_keys);

my $self = {
        'key' => {
                'first' => {
                       'second' => 'value',
                },
        },
};
check_hash_keys($self, 'key', 'first', 'second');

# Print out.
print "ok\n";

# Output:
# ok
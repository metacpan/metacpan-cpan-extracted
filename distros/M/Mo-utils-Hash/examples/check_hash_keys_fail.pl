#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Hash 0.02 qw(check_hash_keys);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => {
                'first' => {
                        'second_typo' => 'value',
                }
        },
};
check_hash_keys($self, 'key', 'first', 'second');

# Print out.
print "ok\n";

# Output like:
# #Error [..Hash.pm:?] Parameter 'key' doesn't contain expected keys.
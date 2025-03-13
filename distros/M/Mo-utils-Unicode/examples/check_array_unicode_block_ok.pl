#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Unicode qw(check_array_unicode_block);

my $self = {
        'key' => [
                'Latin Extended-A',
                'Latin Extended-B',
        ],
};
check_array_unicode_block($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
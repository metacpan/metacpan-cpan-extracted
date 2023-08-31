#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::EAN qw(check_ean);

my $self = {
        'key' => '8590786020177',
};
check_ean($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok

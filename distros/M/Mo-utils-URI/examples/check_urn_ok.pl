#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::URI qw(check_urn);

my $self = {
        'key' => 'urn:isbn:0451450523',
};
check_urn($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
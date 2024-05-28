#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_number_id);

my $self = {
        'key' => '10',
};
check_number_id($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
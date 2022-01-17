#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_array);

my $self = {
        'key' => ['foo'],
};
check_array($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
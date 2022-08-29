#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_bool);
use Test::MockObject;

my $self = {
        'key' => 1,
};
check_bool($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
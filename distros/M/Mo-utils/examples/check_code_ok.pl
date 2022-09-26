#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_code);
use Test::MockObject;

my $self = {
        'key' => sub {},
};
check_code($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
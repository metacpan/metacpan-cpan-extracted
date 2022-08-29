#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_isa);
use Test::MockObject;

my $self = {
        'key' => Test::MockObject->new,
};
check_isa($self, 'key', 'Test::MockObject');

# Print out.
print "ok\n";

# Output:
# ok
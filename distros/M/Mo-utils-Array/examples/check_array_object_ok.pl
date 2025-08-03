#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Array qw(check_array_object);
use Test::MockObject;

my $self = {
        'key' => [
                Test::MockObject->new,
        ],
};
check_array_object($self, 'key', 'Test::MockObject');

# Print out.
print "ok\n";

# Output:
# ok
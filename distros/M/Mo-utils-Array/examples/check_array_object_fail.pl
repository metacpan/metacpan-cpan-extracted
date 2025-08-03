#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Array qw(check_array_object);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => [
                'foo',
        ],
};
check_array_object($self, 'key', 'Test::MockObject');

# Print out.
print "ok\n";

# Output like:
# #Error [..Array.pm:?] Parameter 'key' with array must contain 'Test::MockObject' objects.
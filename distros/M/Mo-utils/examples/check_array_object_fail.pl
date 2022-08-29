#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_array_object);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => [
                'foo',
        ],
};
check_array_object($self, 'key', 'Test::MockObject', 'Value');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Value isn't 'Test::MockObject' object.
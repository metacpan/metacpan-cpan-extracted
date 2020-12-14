#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_isa);

my $self = {
        'key' => 'foo',
};
check_isa($self, 'key', 'Test::MockObject');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' must be a 'Test::MockObject' object.
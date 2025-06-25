#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Number::Range qw(check_int_range);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => -2,
};
check_int_range($self, 'key', 1, 2);

# Print out.
print "ok\n";

# Output like:
# #Error [...Range.pm:?] Parameter 'key' must be a integer between 1 and 2.
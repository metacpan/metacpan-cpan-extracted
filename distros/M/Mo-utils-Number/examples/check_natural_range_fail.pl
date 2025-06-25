#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Number::Range qw(check_natural_range);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 4,
};
check_natural_range($self, 'key', 0, 3);

# Print out.
print "ok\n";

# Output like:
# #Error [...Range.pm:?] Parameter 'key' must be a natural number between 0 and 3.
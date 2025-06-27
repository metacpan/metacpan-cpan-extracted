#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils::Number::Range qw(check_positive_natural_range);

my $self = {
        'key' => -2,
};
check_positive_natural_range($self, 'key', 1, 10);

# Print out.
print "ok\n";

# Output like:
# #Error [...Range.pm:?] Parameter 'key' must be a positive natural number.
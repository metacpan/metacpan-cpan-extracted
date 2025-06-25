#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils::Number::Range qw(check_number_range);

my $self = {
        'key' => 11,
};
check_number_range($self, 'key', 1, 10);

# Print out.
print "ok\n";

# Output like:
# #Error [...Range.pm:?] Parameter 'key' must be a number between 1 and 10.
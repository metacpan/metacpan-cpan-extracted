#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_number_range);

my $self = {
        'key' => 3,
};
check_number_range($self, 'key', 10, 12);

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' must be a number between 10 and 12.

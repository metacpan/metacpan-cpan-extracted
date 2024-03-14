#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_number_min);

my $self = {
        'key' => 10,
};
check_number_min($self, 'key', 11);

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' must be greater than 11.
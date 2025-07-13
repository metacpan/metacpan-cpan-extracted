#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils::Number qw(check_positive_decimal);

my $self = {
        'key' => -1.2,
};
check_positive_decimal($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...Number.pm:?] Parameter 'key' must be a positive decimal number.
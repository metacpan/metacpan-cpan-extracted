#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Number qw(check_natural);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => -2,
};
check_natural($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...Number.pm:?] Parameter 'key' must be a natural number.
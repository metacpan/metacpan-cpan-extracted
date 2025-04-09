#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Number qw(check_int);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 1.2,
};
check_int($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...Number.pm:?] Parameter 'key' must be a integer.
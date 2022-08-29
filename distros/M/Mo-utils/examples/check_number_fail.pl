#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_number);

my $self = {
        'key' => 'foo',
};
check_number($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' must be a number.
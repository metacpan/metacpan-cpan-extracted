#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_length);

my $self = {
        'key' => 'foo',
};
check_length($self, 'key', 2);

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' has length greater than '2'.
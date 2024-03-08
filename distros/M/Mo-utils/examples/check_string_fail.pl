#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_string);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad',
};
check_string($self, 'key', 'foo');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' have expected value.
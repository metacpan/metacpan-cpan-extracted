#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_angle);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 400,
};
check_angle($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' must be a number between 0 and 360.
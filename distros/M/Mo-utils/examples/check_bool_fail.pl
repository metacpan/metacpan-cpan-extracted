#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_bool);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad',
};
check_bool($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' must be a bool (0/1).
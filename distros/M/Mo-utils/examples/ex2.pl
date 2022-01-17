#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_array);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'foo',
};
check_array($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' must be a array.
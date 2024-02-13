#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils qw(check_length_fix);

my $self = {
        'key' => 'foo',
};
check_length_fix($self, 'key', 3);

# Print out.
print "ok\n";

# Output like:
# ok
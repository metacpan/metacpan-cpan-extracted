#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Text qw(check_no_null);

my $self = {
        'key' => 'foo',
};
check_no_null($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
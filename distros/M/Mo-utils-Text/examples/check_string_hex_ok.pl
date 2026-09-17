#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Text qw(check_string_hex);

my $self = {
        'key' => 'ABCDEF0123456789',
};
check_string_hex($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
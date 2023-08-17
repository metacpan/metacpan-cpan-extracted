#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_string_begin);

my $self = {
        'key' => 'http://example.com/foo',
};
check_string_begin($self, 'key', 'http://example.com/');

# Print out.
print "ok\n";

# Output:
# ok
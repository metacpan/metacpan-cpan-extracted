#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils qw(check_regexp);

my $self = {
        'key' => 'https://example.com/1',
};
check_regexp($self, 'key', qr{^https://example\.com/\d+$});

# Print out.
print "ok\n";

# Output:
# ok
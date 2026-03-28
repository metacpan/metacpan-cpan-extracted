#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::UDC qw(check_udc);

my $self = {
        'key' => '821.111(73)-31"19"',
};
check_udc($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
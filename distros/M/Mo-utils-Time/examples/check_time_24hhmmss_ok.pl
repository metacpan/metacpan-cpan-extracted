#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Time qw(check_time_24hhmmss);

my $self = {
        'key' => '12:30:30',
};
check_time_24hhmmss($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
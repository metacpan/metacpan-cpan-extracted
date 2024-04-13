#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Time qw(check_time_24hhmm);

my $self = {
        'key' => '12:32',
};
check_time_24hhmm($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
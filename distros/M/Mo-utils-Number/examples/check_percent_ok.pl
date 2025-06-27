#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number qw(check_percent);

my $self = {
        'key' => '10%',
};
check_percent($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
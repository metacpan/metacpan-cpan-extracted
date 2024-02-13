#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::URI qw(check_location);

my $self = {
        'key' => 'https://skim.cz',
};
check_location($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::URI qw(check_url);

my $self = {
        'key' => 'https://skim.cz',
};
check_url($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
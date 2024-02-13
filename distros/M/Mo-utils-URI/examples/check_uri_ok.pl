#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::URI qw(check_uri);

my $self = {
        'key' => 'https://skim.cz',
};
check_uri($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
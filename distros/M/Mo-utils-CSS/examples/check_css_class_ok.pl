#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::CSS qw(check_css_class);

my $self = {
        'key' => 'foo-bar',
};
check_css_class($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::CSS qw(check_css_color);

my $self = {
        'key' => '#F00',
};
check_css_color($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
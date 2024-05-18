#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::CSS qw(check_css_border);

my $self = {
        'key' => '1px solid red',
};
check_css_border($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
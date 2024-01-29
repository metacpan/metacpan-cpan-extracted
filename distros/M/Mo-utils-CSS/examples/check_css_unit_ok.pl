#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::CSS qw(check_css_unit);

my $self = {
        'key' => '123px',
};
check_css_unit($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
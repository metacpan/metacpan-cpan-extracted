#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Unicode qw(check_unicode_script);

my $self = {
        'key' => 'Thai',
};
check_unicode_script($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
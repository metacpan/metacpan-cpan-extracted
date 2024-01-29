#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Email qw(check_email);

my $self = {
        'key' => 'michal.josef.spacek@gmail.com',
};
check_email($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Currency qw(check_currency_code);

my $self = {
        'key' => 'CZK',
};
check_currency_code($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
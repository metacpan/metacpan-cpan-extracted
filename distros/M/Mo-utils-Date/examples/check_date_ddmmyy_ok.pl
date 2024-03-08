#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Date qw(check_date_ddmmyy);

my $self = {
        'key' => '151120',
};
check_date_ddmmyy($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
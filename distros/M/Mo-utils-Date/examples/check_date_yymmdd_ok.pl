#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Date qw(check_date_yymmdd);

my $self = {
        'key' => '201115',
};
check_date_yymmdd($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
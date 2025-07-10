#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::CEFACT qw(check_cefact_unit);

my $self = {
        'key' => 'DLT',
};
check_cefact_unit($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
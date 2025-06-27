#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils::Number::Range qw(check_percent_range);

my $self = {
        'key' => 11,
};
check_percent_range($self, 'key', 1, 10);

# Print out.
print "ok\n";

# Output like:
# #Error [...Range.pm:?] Parameter 'key' has bad percent value (missing %).
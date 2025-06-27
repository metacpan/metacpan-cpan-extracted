#!/usr/bin/env perl

use strict;
use warnings;

$Error::Pure::TYPE = 'Error';

use Mo::utils::Number qw(check_percent);

my $self = {
        'key' => 'foo',
};
check_percent($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...Number.pm:?] Parameter 'key' has bad percent value.
#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_strings);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bar',
};
check_strings($self, 'key', ['foo', 'value']);

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' must be one of defined strings.
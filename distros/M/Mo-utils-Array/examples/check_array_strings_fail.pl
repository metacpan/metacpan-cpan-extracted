#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Array qw(check_array_strings);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => ['bad'],
};
check_array_strings($self, 'key', ['value']);

# Print out.
print "ok\n";

# Output like:
# #Error [..Array.pm:?] Parameter 'key' must be one of the defined strings.
#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::URI qw(check_location);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'urn:isbn:9788072044948',
};
check_location($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' doesn't contain valid location.
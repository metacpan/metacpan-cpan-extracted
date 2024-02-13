#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::URI qw(check_urn);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_urn',
};
check_urn($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' doesn't contain valid URN.
#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::CSS qw(check_css_unit);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => '12',
};
check_css_unit($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain unit.
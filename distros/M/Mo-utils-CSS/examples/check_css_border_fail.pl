#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::CSS qw(check_css_border);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad',
};
check_css_border($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...CSS.pm:?] Parameter 'key' has bad border style.
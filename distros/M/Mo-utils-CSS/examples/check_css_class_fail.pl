#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::CSS qw(check_css_class);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => '1xxx',
};
check_css_class($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...CSS.pm:?] Parameter 'key' has bad CSS class name (number of begin).
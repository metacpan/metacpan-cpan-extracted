#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::CSS qw(check_css_color);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xxx',
};
check_css_color($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...CSS.pm:?] Parameter 'key' has bad color name.
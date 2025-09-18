#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Currency qw(check_currency_code);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xx',
};
check_currency_code($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...Currency.pm:?] Parameter 'key' must be a valid currency code.
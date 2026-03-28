#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::UDC qw(check_udc);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => '821:.5',
};
check_udc($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...UDC.pm:?] Parameter 'key' doesn't contain valid Universal Decimal Classification string.
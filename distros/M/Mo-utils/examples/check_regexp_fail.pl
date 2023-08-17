#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_regexp);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'https://example.com/bad',
};
check_regexp($self, 'key', qr{^https://example\.com/\d+$});

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' does not match the specified regular expression.
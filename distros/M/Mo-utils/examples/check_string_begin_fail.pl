#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils qw(check_string_begin);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'http://example/foo',
};
check_string_begin($self, 'key', 'http://example.com/');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' must begin with defined string base.
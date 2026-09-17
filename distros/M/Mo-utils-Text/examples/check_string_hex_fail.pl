#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Text qw(check_string_hex);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'foo',
};
check_string_hex($self, 'key');

# Output:
# #Error [../Text.pm:33] Parameter 'key' must contain hexadecimal string.
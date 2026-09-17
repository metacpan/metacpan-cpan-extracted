#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Text qw(check_no_null);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => "foo\0",
};
check_no_null($self, 'key');

# Output:
# #Error [../Text.pm:19] Parameter 'key' must not contain NULL on the end of string.
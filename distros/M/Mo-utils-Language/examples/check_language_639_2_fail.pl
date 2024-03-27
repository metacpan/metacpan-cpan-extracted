#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Language qw(check_language_639_2);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xxx',
};
check_language_639_2($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 639-2 code.
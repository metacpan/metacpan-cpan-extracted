#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Language qw(check_language_639_1);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xx',
};
check_language_639_1($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 639-1 code.
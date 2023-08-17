#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Language qw(check_language);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xx',
};
check_language($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Language code 'xx' isn't ISO 639-1 code.
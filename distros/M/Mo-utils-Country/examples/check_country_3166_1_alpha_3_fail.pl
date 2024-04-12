#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Country qw(check_country_3166_1_alpha_3);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xxx',
};
check_country_3166_1_alpha_3($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 3166-2 alpha-3 code.
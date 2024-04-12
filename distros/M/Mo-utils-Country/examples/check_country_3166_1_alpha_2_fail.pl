#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Country qw(check_country_3166_1_alpha_2);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xx',
};
check_country_3166_1_alpha_2($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain valid ISO 3166-1 alpha-2 code.
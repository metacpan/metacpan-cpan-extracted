#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Country qw(check_country_3166_1_alpha_2);

my $self = {
        'key' => 'cz',
};
check_country_3166_1_alpha_2($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
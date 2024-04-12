#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Country qw(check_country_3166_1_alpha_3);

my $self = {
        'key' => 'cze',
};
check_country_3166_1_alpha_3($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Language 0.05 qw(check_language_639_2);

my $self = {
        'key' => 'eng',
};
check_language_639_2($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
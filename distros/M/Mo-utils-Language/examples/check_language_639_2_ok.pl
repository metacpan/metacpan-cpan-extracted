#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Language qw(check_language_639_2);

my $self = {
        'key' => 'eng',
};
check_language_639_2($self, 'eng');

# Print out.
print "ok\n";

# Output:
# ok
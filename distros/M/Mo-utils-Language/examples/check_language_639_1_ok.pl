#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Language 0.05 qw(check_language_639_1);

my $self = {
        'key' => 'en',
};
check_language_639_1($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::TimeZone qw(check_timezone_iana);

my $self = {
        'key' => 'Europe/Prague',
};
check_timezone_iana($self, 'key');

# Print out.
print "ok\n";

# Output:
# ok
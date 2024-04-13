#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Time qw(check_time_24hhmmss);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad',
};
check_time_24hhmmss($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain valid time in HH:MM:SS format.
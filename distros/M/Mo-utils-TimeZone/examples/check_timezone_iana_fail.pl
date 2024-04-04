#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::TimeZone qw(check_timezone_iana);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'BAD',
};
check_timezone_iana($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] Parameter 'key' doesn't contain valid IANA timezone code.
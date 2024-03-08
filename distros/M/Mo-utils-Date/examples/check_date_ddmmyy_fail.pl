#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Date qw(check_date_ddmmyy);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'foo',
};
check_date_ddmmyy($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..Utils.pm:?] Parameter 'key' for date is in bad format.
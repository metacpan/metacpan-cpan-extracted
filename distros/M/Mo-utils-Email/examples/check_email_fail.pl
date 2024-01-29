#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Email qw(check_email);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'michal.josef.špaček@gmail.com',
};
check_email($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' doesn't contain valid email.
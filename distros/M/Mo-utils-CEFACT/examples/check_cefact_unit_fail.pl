#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::CEFACT qw(check_cefact_unit);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xx',
};
check_cefact_unit($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...CEFACT.pm:?] Parameter 'key' must be a UN/CEFACT unit common code.
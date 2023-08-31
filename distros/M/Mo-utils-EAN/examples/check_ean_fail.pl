#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::EAN qw(check_ean);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'xx',
};
check_ean($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [...utils.pm:?] EAN code doesn't valid.
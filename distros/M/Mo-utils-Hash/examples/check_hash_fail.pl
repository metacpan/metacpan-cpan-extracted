#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Hash qw(check_hash);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad',
};
check_hash($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..Utils.pm:?] Parameter 'key' isn't hash reference.
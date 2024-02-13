#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::URI qw(check_uri);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_uri',
};
check_uri($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' doesn't contain valid URI.
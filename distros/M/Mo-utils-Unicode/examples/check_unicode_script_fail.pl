#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Unicode qw(check_unicode_script);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => 'bad_script',
};
check_unicode_script($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' contains invalid Unicode script.
#!/usr/bin/env perl

use strict;
use warnings;

use Error::Pure;
use Mo::utils::Unicode qw(check_array_unicode_block);

$Error::Pure::TYPE = 'Error';

my $self = {
        'key' => [
               'Bad Unicode block',
         ],
};
check_array_unicode_block($self, 'key');

# Print out.
print "ok\n";

# Output like:
# #Error [..utils.pm:?] Parameter 'key' contains invalid Unicode block.
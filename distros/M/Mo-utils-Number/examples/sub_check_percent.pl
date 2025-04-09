#!/usr/bin/env perl

use strict;
use warnings;

use Mo::utils::Number::Utils qw(sub_check_percent);

my $ret = sub_check_percent('20%', 'key', 'percent value', 'user value');
if (! defined $ret) {
        print "Returns undef.\n";
}

# Output:
# Returns undef.
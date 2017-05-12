#!/usr/bin/perl

use strict;
use warnings;

my $buf = '';
while (<STDIN>) {
    $buf .= $_;
}

print $buf;
exit 0;
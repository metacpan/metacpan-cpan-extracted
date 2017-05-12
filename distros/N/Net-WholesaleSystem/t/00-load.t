#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Net::WholesaleSystem');
}

diag("Testing Net::WholesaleSystem $Net::WholesaleSystem::VERSION, Perl $], $^X"
);

1;

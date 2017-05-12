#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Pod::Loom');
}

diag("Testing Pod::Loom $Pod::Loom::VERSION");

#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 2;

BEGIN {
    use_ok('Palm::PDB');
    use_ok('Palm::Raw');
}

diag("Testing Palm::PDB $Palm::PDB::VERSION");

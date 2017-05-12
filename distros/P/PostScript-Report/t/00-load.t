#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('PostScript::Report');
}

diag("Testing PostScript::Report $PostScript::Report::VERSION");

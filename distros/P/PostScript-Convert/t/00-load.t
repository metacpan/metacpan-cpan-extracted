#! /usr/bin/perl
#---------------------------------------------------------------------
# 00-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('PostScript::Convert');
}

diag("Testing PostScript::Convert $PostScript::Convert::VERSION");

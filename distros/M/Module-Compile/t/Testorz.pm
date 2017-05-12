package Testorz;
use strict;
use warnings;

use Module::Compile -base;

sub pmc_compile {
    s/^/# /gm;
    return <<"_";
# orz...\n
$_
pass 'orz was here';
pass __FILE__;
_
}

1;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use t::scan::Util;

test(<<'TEST'); # ETHER/Pod-Coverage-Moose-0.07/t/lib/TestOverload.pm
use if !eval { require Moose; Moose->VERSION('2.1300') },
    'MooseX::Role::WithOverloading';
TEST

done_testing;

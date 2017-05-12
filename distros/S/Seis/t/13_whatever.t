use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

# *.uc is same as { $^x.uc }.
# It means (sub { shift->uc(@args) })->()
is compile('<a B c>.map(*.uc).join(" ")'), 'A B C';

done_testing;


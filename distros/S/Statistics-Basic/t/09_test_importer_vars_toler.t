
use t::locale_hack;

BEGIN { $ENV{TOLER} = 1 }

use Test;
use Statistics::Basic qw(:all toler);

plan tests => 1;

my $mean = mean(1,3,7);
ok($mean != 3.7);

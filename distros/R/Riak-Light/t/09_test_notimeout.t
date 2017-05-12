use Test::More tests => 2;
use FindBin qw($Bin);
use lib "$Bin/tlib";
use TestTimeout qw(test_normal_wait);

test_normal_wait(undef);
test_normal_wait( undef, 1 );

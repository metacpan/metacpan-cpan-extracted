use strict;
use warnings;
use Test::More tests => 4;

use_ok('SWISH::3');

ok( my $s3  = SWISH::3->new, "new s3" );
ok( my $s32 = SWISH::3->new, "another new s3" );

undef $s3;
undef $s32;

is( SWISH::3->get_memcount, 0, "memcount is 0" );

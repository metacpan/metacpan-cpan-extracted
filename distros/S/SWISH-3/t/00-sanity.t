use strict;
use warnings;
use Test::More tests => 3;

use_ok('SWISH::3');

diag(SWISH::3->_show_sizes());

ok( my $s3 = SWISH::3->new(), "new object" );

ok( my $s3_2 = SWISH::3->new(), "second new object" );

$s3_2 = 0;

# this generates mem leak??
system("$^X -Mblib -MSWISH::3 -e '\$s = SWISH::3->new'");

sub foo {
    warn sprintf( "\$s3 refcount = %d\n", $s3->refcount );

}

foo();

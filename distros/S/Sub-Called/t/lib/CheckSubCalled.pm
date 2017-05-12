package CheckSubCalled;

use strict;
use warnings;
use Test::More;
use Sub::Called qw(with_ampersand);

test();
&test2();

sub test {
    ok( !with_ampersand() );
}

sub test2 {
    ok( with_ampersand() );
}

1;
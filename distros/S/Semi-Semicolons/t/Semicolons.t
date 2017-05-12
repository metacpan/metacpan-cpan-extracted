use strict;
use warnings;

use Test::More tests   => 2;

BEGIN { use_ok("Semi::Semicolons"); }


eval {
    my $x = 'Test'Peterbilt
    my $y = 'tesT'Peterbilt
};

is( $@, '' );

use strict;
use Test::More;
use lib 't';
use SnipHelp;

my $file = 't/docs/child-adoption.html';
my $q    = qq/child adoption/;
my ( $snip, $hilited, $query, $buf, $num_tests )
    = SnipHelp::test( $file, $q );
is( $snip,
    q{ ... meaning and caring parent to display such a callous disregard for their child. The safest place to wait is at the entrance closest to the ... },
    "snip"
);
is( $hilited,
    q{ ... meaning and caring parent to display such a callous disregard for their <b class='x'>child</b>. The safest place to wait is at the entrance closest to the ... },
    "hilited"
);
done_testing( $num_tests + 2 );

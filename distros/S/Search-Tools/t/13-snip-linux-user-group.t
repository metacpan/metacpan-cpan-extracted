use strict;
use Test::More;
use lib 't';
use SnipHelp;

my $file = 't/docs/linux-user-group.html';
my $q    = qq/"linux user group"/;
my ( $snip, $hilited, $query, $buf, $num_tests )
    = SnipHelp::test( $file, $q );
is( $snip,
    qq{ ... Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape Linux User Group : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group ... },
    "snip"
);
is( $hilited,
    qq{ ... Operating System Ubuntu Linux : The Friendly Linux Operating System The Western Cape <b class='x'>Linux User Group</b> : Cape Town LUG Software Process Improvement Network (SPIN) : Software development user group ... },
    "hilited"
);

done_testing( $num_tests + 2 );

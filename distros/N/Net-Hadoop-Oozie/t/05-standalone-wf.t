use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok("Net::Hadoop::Oozie");
}

SKIP: {
    skip "No OOZIE_URL in environment", 1 if ! $ENV{OOZIE_URL};

    ok( 1, 'Tests are not yet implemented ...');
}

done_testing();

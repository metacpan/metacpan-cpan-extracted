use 5.010;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok( 'DateTimeX::Format::Ago' ) || print "Ago module not ok!\n";
    use_ok( 'Mojolicious::Plugin::TimeAgo' ) || print "TimeAgo plugin not ok!\n";
}

done_testing;

use warnings;
use strict;

use Test::More;

my $ok;

BEGIN {
    $ok = eval "use Script::Singleton; 1;";
}

is $ok, undef, "use Script::Singleton croaks if no glue sent in";

done_testing;

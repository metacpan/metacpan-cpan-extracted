use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Riemann::Client::Protocol'); }

for (qw/ Event State Query Msg /) {
    ok($_->can('encode'), "$_ can encode");
}

done_testing();

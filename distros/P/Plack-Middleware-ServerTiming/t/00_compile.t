use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Plack::ServerTiming
    Plack::Middleware::ServerTiming
);

done_testing;


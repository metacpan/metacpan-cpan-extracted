use strict;
use warnings;
use Test::More;
use Plack::Middleware::Throttle::Lite::Backend::Simple;

can_ok 'Plack::Middleware::Throttle::Lite::Backend::Simple', qw(
    increment
    reqs_done
    reqs_max
    units
    settings
    expire_in
    cache_key
    ymdh
);

done_testing();

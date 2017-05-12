use strict;
use warnings;

use lib 'lib';
use Test::More;

BEGIN {
    use_ok('Plack::Middleware::TrailingSlash');
}

done_testing;

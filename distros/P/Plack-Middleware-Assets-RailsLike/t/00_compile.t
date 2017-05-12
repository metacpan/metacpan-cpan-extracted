use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    Plack::Middleware::Assets::RailsLike
    Plack::Middleware::Assets::RailsLike::Compiler
);

done_testing;

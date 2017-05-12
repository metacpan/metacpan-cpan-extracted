use strict;
use warnings;

use Test::Fatal;
use Test::More 0.96;

use lib 't/lib';
use Specio::Library::XY;

require Specio::Library::Conflict;

like(
    exception { Specio::Library::Conflict->import },
    qr/\QThe main package already has a type named X/,
    'Got an exception when a library import conflicts with already declared types'
);

done_testing();

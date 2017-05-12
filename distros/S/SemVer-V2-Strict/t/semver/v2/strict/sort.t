use strict;
use warnings;
use utf8;

use t::Util;
use SemVer::V2::Strict;

subtest basic => sub {
    cmp_deeply
        [ SemVer::V2::Strict->sort('1.0.0', '0.1.0', '1.0.0-beta', '0.1.2') ],
        [ '0.1.0', '0.1.2', '1.0.0-beta', '1.0.0' ];
};

done_testing;

use strict;
use warnings;
use Test::More 0.88;
use Test::Exception;

use Sub::Sequence;

{
    throws_ok {
        seq 0, 1, sub {};
    } qr/^First arg must ARRAY REF/, 'not ARRAY REF';

    throws_ok {
        seq [], 0, sub {};
    } qr/^Second arg is wrong/, 'wrong count';

    throws_ok {
        seq [], 1, 1;
    } qr/^Third arg must CODE REF/, 'not CODE REF';
}

done_testing;

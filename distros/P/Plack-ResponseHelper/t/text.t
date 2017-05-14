use strict;
use warnings;
use utf8;

use Encode;
use Test::More;
use Test::Deep;

use Plack::ResponseHelper text => 'Text';

cmp_deeply(
    respond(text => 'abc'),
    [
        200,
        [
            'Content-Type',
            'text/plain'
        ],
        [
            'abc'
        ]
    ],
    'string'
); 

cmp_deeply(
    respond(text => ['abc', 'def', 'ляляля']),
    [
        200,
        [
            'Content-Type',
            'text/plain'
        ],
        [
            'abc',
            'def',
            encode('utf-8', 'ляляля')
        ]
    ],
    'arrayref'
); 

done_testing;

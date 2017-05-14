use strict;
use warnings;
use Test::Exception;
use Test::More;
use Test::Deep;

use Plack::ResponseHelper redirect => 'Redirect',
                          page404  => [
                              'Redirect',
                              {default_status => 404, default_location => '/404.html'}
                          ];

cmp_deeply(
    respond(redirect => '/'),
    [
        302,
        [
            'Location',
            '/'
        ],
        []
    ],
    'ok'
); 
cmp_deeply(
    respond(page404 => undef),
    [
        404,
        [
            'Location',
            '/404.html'
        ],
        []
    ],
    'ok'
); 
dies_ok {
    respond redirect => '';
} 'empty location';
lives_ok {
    respond redirect => '0';
} 'empty location';

done_testing;

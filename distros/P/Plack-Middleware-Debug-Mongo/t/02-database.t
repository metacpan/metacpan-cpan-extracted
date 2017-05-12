use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::FakeMongoDB;

t::lib::FakeMongoDB->run;

use Plack::Middleware::Debug::Mongo::Database;
can_ok 'Plack::Middleware::Debug::Mongo::Database', qw/prepare_app run/;

# simple application
my $app = sub {[ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ]};

$app = builder {
    enable 'Debug',
        panels => [
            [ 'Mongo::Database', connection => { host => 'mongodb://localhost:27017', db_name => 'sampledb' } ],
        ];
    $app;
};

my @items = (
    'sampledb' => {
        'avgObjSize'        => 643.318918918919,
        'collections'       => 8,
        'flags'             => 1,
        'dataSize'          => 476056,
        'db'                => 'sampledb',
        'fileSize'          => 201326592,
        'indexSize'         => 81760,
        'indexes'           => 6,
        'nsSizeMB'          => 16,
        'numExtents'        => 11,
        'objects'           => 740,
        'ok'                => 1,
        'storageSize'       => 585728,
    },
    'models' => {
        'avgObjSize'        => 1459.75,
        'count'             => 16,
        'flags'             => 1,
        'indexSizes._id_'   => 8176,
        'lastExtentSize'    => 24576,
        'nindexes'          => 1,
        'ns'                => 'sampledb.models',
        'numExtents'        => 1,
        'ok'                => 1,
        'paddingFactor'     => 1,
        'size'              => 23356,
        'storageSize'       => 24576,
        'totalIndexSize'    => 8176,
    },
    'sessions' => {
        'avgObjSize'        => 1074.67768595041,
        'count'             => 363,
        'flags'             => 1,
        'indexSizes._id_'   => 24528,
        'lastExtentSize'    => 327680,
        'nindexes'          => 1,
        'ns'                => 'sampledb.sessions',
        'numExtents'        => 3,
        'ok'                => 1,
        'paddingFactor'     => 1,
        'size'              => 390108,
        'storageSize'       => 430080,
        'totalIndexSize'    => 24528,
    },
);

test_psgi $app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET '/');
    is $res->code, 200, 'response code 200';

    like $res->content,
        qr|<a href="#" title="Mongo::Database" class="plDebugDatabase\d+Panel">|m,
        'database panel found';

    like $res->content,
        qr|<small>sampledb</small>|,
        'subtitle points to sampledb';

    while (my ($item, $tests) = splice(@items, 0, 2)) {
        like $res->content, qr|<h3>.*: $item</h3>|, 'found statistics for ' . $item;
        while (my ($key, $value) = each(%$tests)) {
            like $res->content,
                qr|<td>$key</td>[.\s\n\r]*<td>$value</td>|, 'got correct value for ' . $key . ' [' . $item . ']';
        }
    }
};

done_testing();

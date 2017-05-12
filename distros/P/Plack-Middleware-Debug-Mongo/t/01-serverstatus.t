use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::FakeMongoDB;

t::lib::FakeMongoDB->run;

use Plack::Middleware::Debug::Mongo::ServerStatus 'hashwalk';
can_ok 'Plack::Middleware::Debug::Mongo::ServerStatus', qw/prepare_app run/;
ok defined(&hashwalk), 'hashwalk imported okay';

# simple application
my $app = sub {[ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ]};

$app = builder {
    enable 'Debug',
        panels => [
            [ 'Mongo::ServerStatus', connection => { host => 'mongodb://localhost:27017', db_name => 'sampledb' } ],
        ];
    $app;
};

my @items = (
    'ok'                    => 1,
    'version'               => '2.2.0',
    'uptime'                => 1738371,
    'process'               => 'mongod',
    'network.bytesIn'       => 43218,
    'network.bytesOut'      => 9235789924,
    'network.numRequests'   => 548,
    'mem.bits'              => 64,
    'mem.mapped'            => 1056,
    'mem.mappedWithJournal' => 2112,
    'mem.note'              => 'not all mem.*',
    'mem.supported'         => 'false',
    'writeBacksQueued'      => 'true',
);

test_psgi $app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET '/');
    is $res->code, 200, 'response code 200';

    like $res->content,
        qr|<a href="#" title="Mongo::ServerStatus" class="plDebugServerStatus\d+Panel">|m,
        'status panel found';

    like $res->content,
        qr|<small>Version: \d\.\d{1,2}\.\d{1,2}</small>|,
        'subtitle points to mongod version';

    while (my ($key, $value) = splice(@items, 0, 2)) {
        like $res->content,
            qr|<td>$key</td>[.\s\n\r]*<td>$value</td>|m,
            'got expected value for ' . $key;
    }
};

done_testing();

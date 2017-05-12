use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::FakeRedis;

t::lib::FakeRedis->run;

my $app = builder {
    enable 'Debug',
        panels => [
            [ 'Redis::Info', instance => 'localhost:6379' ],
        ];
    sub { [200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ]] };
};

my @content_bundle = (
    db0_keys            =>                    167, 'total keys in db0',
    db0_expires         =>                    145, 'expires keys in db0',
    db1_keys            =>                     75, 'total keys in db1',
    db1_expires         =>                      0, 'expires keys in db1',
    redis_version       => '\d\.\d{1,2}\.\d{1,2}', 'redis server version',
    uptime_in_seconds   =>                1591647, 'redis server uptime',
    role                =>               'master', 'redis server role',
    os                  =>      'Free.*\d\.\d-.*', 'run under os',
    run_id              =>         '[a-f0-9]{40}', 'match run_id',
    used_cpu_sys        =>            '\d\.\d{2}', 'match sys cpu usage',
    used_cpu_user       =>            '\d\.\d{2}', 'match user cpu usage',
);

test_psgi $app, sub {
    my ($cb) = @_;

    my $res = $cb->(GET '/');
    is $res->code, 200, 'response code 200';

    like $res->content,
        qr|<a href="#" title="Redis::Info" class="plDebugInfo\d+Panel">|m,
        'panel found';

    like $res->content,
        qr|<small>Version: \d\.\d{1,2}\.\d{1,2}</small>|,
        'subtitle points to redis version';

    while (my ($metric, $expected, $description) = splice(@content_bundle, 0, 3)) {
        like $res->content, qr|<td>$metric</td>[.\s\n\r]*<td>$expected</td>|m, $description;
    }
};

done_testing();

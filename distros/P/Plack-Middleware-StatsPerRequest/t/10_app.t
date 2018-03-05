use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Measure::Everything::Adapter;
Measure::Everything::Adapter->set('Test');

use Measure::Everything qw($stats);
use Log::Any::Test;
use Log::Any qw($log);

use Time::HiRes qw(usleep);

my $app = sub {
    my $env = shift;

    return [ 200, [ 'Content-Type' => 'text/plain' ],
        ['measure everything!'] ];
};

subtest 'all defaults' => sub {

    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest";
        $app
    };
    my @tests = (
        [qw(/ /)],
        [qw(/foo /foo)],
        [qw(/123456/bar /:int/bar)],
        [   qw(/123456/view/affebeef/do/9999999999.html /:int/view/:hex/do/:int.html)
        ],
    );

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            foreach my $t (@tests) {
                my $res = $cb->( GET "http://localhost" . $t->[0], );
                is( $res->code, 200, 'request ' . $t->[0] );
            }
        }
    );

    my $collected = $stats->get_stats;
    for ( my $i = 0; $i < @tests; $i++ ) {
        subtest 'stats for request ' . $tests[$i]->[0] => sub {
            my $data = $collected->[$i];
            is( $data->[0], 'http_request', 'metric name' );
            is( $data->[1]{hit}, 1, 'value: hit' );
            ok( $data->[1]{request_time}, 'value: request time' );
            is( $data->[2]{app},    'unknown', 'tag: app name' );
            is( $data->[2]{method}, 'GET',     'tag: method=GET' );
            is( $data->[2]{status}, 200,       'tag: status=200' );
            is( $data->[2]{path},
                $tests[$i]->[1], 'tag: path ' . $tests[$i]->[1] );
            }
    }
    $stats->reset;
};

subtest 'app_name, metric_name' => sub {
    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest",
            app_name    => 'test',
            metric_name => 'http';
        $app
    };

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "http://localhost/custom-names", );
            is( $res->code, 200, 'request status' );
        }
    );

    my $collected = $stats->get_stats;
    my $data      = shift(@$collected);
    is( $data->[0],       'http',          'metric name' );
    is( $data->[2]{app},  'test',          'tag: app name' );
    is( $data->[2]{path}, '/custom-names', 'tag: path /custom-names' );
    $stats->reset;
};

subtest 'no path_cleanups' => sub {
    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest", path_cleanups => [];
        $app
    };

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            my $res = $cb->(
                GET
                    "http://localhost/123456/view/affebeef/do/9999999999.html",
            );
            is( $res->code, 200, 'request' );
        }
    );

    my $collected = $stats->get_stats;
    my $data      = shift(@$collected);
    is( $data->[2]{path},
        '/123456/view/affebeef/do/9999999999.html',
        'tag: path without cleanup'
    );
    $stats->reset;
};

subtest 'custom path_cleanups' => sub {
    my $cleanup = sub {
        my $path = shift;
        $path =~ s{\/}{}g;
        return uc( substr( $path, 0, 5 ) );
    };

    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest",
            path_cleanups => [$cleanup];
        $app
    };

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "http://localhost/go/to/home", );
            is( $res->code, 200, 'request' );
        }
    );

    my $collected = $stats->get_stats;
    my $data      = shift(@$collected);
    is( $data->[2]{path}, 'GOTOH', 'tag: path with custom cleanup' );
    $stats->reset;
};

subtest 'add_headers' => sub {

    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest",
            add_headers => [ 'X-SOME-HEADER', 'Accept-Language' ];
        $app
    };

    my @tests = (
        [   { 'Accept-Language' => 'en-US,en;q=0.5' },
            {   'header_accept-language' => 'en-US,en;q=0.5',
                'header_x-some-header'   => 'not_set'
            }
        ],
        [   { 'x-some-header' => 'foo' },
            {   'header_accept-language' => 'not_set',
                'header_x-some-header'   => 'foo'
            }
        ], [
            {   'Accept-Language' => 'en-US,en;q=0.5',
                'x-some-header'   => 'foo'
            },
            {   'header_accept-language' => 'en-US,en;q=0.5',
                'header_x-some-header'   => 'foo'
            }
        ], [
            {   'X-SOME-OTHER'    => 1,
                'Accept-Language' => 'en-US,en;q=0.5',
                'x-some-header'   => 'foo'
            },
            {   'header_accept-language' => 'en-US,en;q=0.5',
                'header_x-some-header'   => 'foo'
            }
        ],
    );

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            foreach my $t (@tests) {
                my $res = $cb->( GET "http://localhost", %{ $t->[0] } );
                is( $res->code, 200, 'request' );
            }
        }
    );

    my $collected = $stats->get_stats;
    for ( my $i = 0; $i < @tests; $i++ ) {
        subtest 'stats for request ' . $i => sub {
            my $data   = $collected->[$i];
            my $expect = $tests[$i]->[1];
            while ( my ( $header, $value ) = each %$expect ) {
                is( $data->[2]{$header},
                    $value, 'got header ' . $header . ': ' . $value );
            }
            is( $data->[2]{'header_x-some-other'},
                undef, 'no header_x-some-other' );
        };
    }

    $stats->reset;
};

subtest 'has_headers' => sub {

    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest",
            has_headers => [ 'X-SOME-HEADER', 'Accept-Language' ];
        $app
    };

    my @tests = (
        [   { 'Accept-Language' => 'en-US,en;q=0.5' },
            {   'has_header_accept-language' => 1,
                'has_header_x-some-header'   => 0
            }
        ],
        [   { 'x-some-header' => 'foo' },
            {   'has_header_accept-language' => 0,
                'has_header_x-some-header'   => 1
            }
        ], [
            {   'Accept-Language' => 'en-US,en;q=0.5',
                'x-some-header'   => 'foo'
            },
            {   'has_header_accept-language' => 1,
                'has_header_x-some-header'   => 1
            }
        ], [
            {   'X-SOME-OTHER'    => 1,
                'Accept-Language' => 'en-US,en;q=0.5',
                'x-some-header'   => 'foo'
            },
            {   'has_header_accept-language' => 1,
                'has_header_x-some-header'   => 1
            }
        ],
    );

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            foreach my $t (@tests) {
                my $res = $cb->( GET "http://localhost", %{ $t->[0] } );
                is( $res->code, 200, 'request' );
            }
        }
    );

    my $collected = $stats->get_stats;
    for ( my $i = 0; $i < @tests; $i++ ) {
        subtest 'stats for request ' . $i => sub {
            my $data   = $collected->[$i];
            my $expect = $tests[$i]->[1];
            while ( my ( $header, $value ) = each %$expect ) {
                is( $data->[2]{$header},
                    $value, 'got has_header ' . $header . ': ' . $value );
            }
            is( $data->[2]{'header_x-some-other'},
                undef, 'no has_header_x-some-other' );
        };
    }

    $stats->reset;
};

subtest 'add/has_headers not an array' => sub {
    $log->clear;
    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest",
            has_headers => 'X-SOME-HEADER',
            add_headers => 'Accept-Language';
        $app
    };

    my $msgs = $log->msgs;
    like(
        $msgs->[0]{message},
        qr/add_headers has to be an ARRAYREF, ignoring Accept-Language/,
        'got warning about bad add_headers'
    );
    like(
        $msgs->[1]{message},
        qr/has_headers has to be an ARRAYREF, ignoring X-SOME-HEADER/,
        'got warning about bad has_headers'
    );
};

my $slow_app = sub {
    my $env = shift;
    usleep(1_500_000);
    return [ 200, [ 'Content-Type' => 'text/plain' ],
        ['measure everything!'] ];
};

subtest 'long_request' => sub {
    $log->clear;
    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest", long_request => 1;
        $slow_app
    };

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "http://localhost", );
            is( $res->code, 200, 'request' );

        }
    );

    my $collected = $stats->get_stats;
    my $data      = shift(@$collected);
    like( $data->[1]{request_time}, qr/^1\.\d+$/, 'request_time' );
    my $logmsg = $log->msgs->[0];
    is( $logmsg->{category},
        'Plack::Middleware::StatsPerRequest',
        'log msg category'
    );
    is( $logmsg->{level}, 'warning', 'log level' );
    like( $logmsg->{message}, qr/Long request, took 1\./, 'log message' );

    $log->clear;
    $stats->reset;
};

subtest "long_request, but we don't care" => sub {
    $log->clear;
    my $handler = builder {
        enable "Plack::Middleware::StatsPerRequest", long_request => 0;
        $slow_app
    };

    test_psgi(
        app    => $handler,
        client => sub {
            my $cb = shift;

            my $res = $cb->( GET "http://localhost", );
            is( $res->code, 200, 'request' );

        }
    );

    my $collected = $stats->get_stats;
    my $data      = shift(@$collected);
    like( $data->[1]{request_time}, qr/^1\.\d+$/, 'request_time' );
    is( $log->msgs->[0], undef, 'no log message!' );

    $log->clear;
    $stats->reset;
};

done_testing;

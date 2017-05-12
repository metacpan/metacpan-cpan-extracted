use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use Test::More tests => 23;
use Test::TCP;

test_tcp(
    server => sub {
        my $port = shift;
        exec($^X, '-Mblib', '-MAnyEvent', '-MMonitor::MetricsAPI', '-e',
            q|  my $condvar = AnyEvent->condvar;
                my $coll = Monitor::MetricsAPI->create(
                    listen => '127.0.0.1:8200',
                    metrics => {
                        test => {
                            foo => 'counter',
                            bar => 'gauge',
                        },
                        xyzzy => sub { "Nothing happens." },
                    }
                );
                $coll->metric('test/foo')->set(50);
                $coll->metric('test/bar')->set(200);
                $condvar->recv;
             |
        );
        exit 1;
    },
    client => sub {
        my $port = shift;

        my $ua = LWP::UserAgent->new;
        my $resp = $ua->get('http://127.0.0.1:8200/metric/test/foo');

        ok($resp->is_success, 'http ok');
        cmp_ok($resp->header('Content-type'), 'eq', 'application/json', 'api response is JSON');

        my $data;
        eval { $data = decode_json($resp->decoded_content); };

        ok(defined $data && ref($data) eq 'HASH', 'json response decoded');
        cmp_ok($data->{'status'}, 'eq', 'ok', 'api returned status ok');

        ok(exists $data->{'metrics'}{'test'}{'foo'},   'test metric exists in response');
        ok(! exists $data->{'metrics'}{'test'}{'bar'}, 'metric outside request path does not exist in response');
        ok(! exists $data->{'metrics'}{'xyzzy'},       'metric outside request path does not exist in response');

        cmp_ok($data->{'metrics'}{'test'}{'foo'}, '==', 50, 'expected value of metric found');

        $resp = $ua->get('http://127.0.0.1:8200/metrics/test');
        eval { $data = decode_json($resp->decoded_content); };

        ok($resp->is_success, 'http ok');
        cmp_ok($resp->header('Content-type'), 'eq', 'application/json', 'api response is JSON');

        ok(exists $data->{'metrics'}{'test'}{'foo'}, 'test metric exists in response');
        ok(exists $data->{'metrics'}{'test'}{'bar'}, 'test metric exists in response');
        ok(! exists $data->{'metrics'}{'xyzzy'},     'metric outside request path does not exist in response');

        cmp_ok($data->{'metrics'}{'test'}{'foo'}, '==', 50,  'expected value of metric found');
        cmp_ok($data->{'metrics'}{'test'}{'bar'}, '==', 200, 'expected value of metric found');

        $resp = $ua->get('http://127.0.0.1:8200/all');
        eval { $data = decode_json($resp->decoded_content); };

        ok($resp->is_success, 'http ok');
        cmp_ok($resp->header('Content-type'), 'eq', 'application/json', 'api response is JSON');

        ok(exists $data->{'metrics'}{'test'}{'foo'}, 'test metric exists in response');
        ok(exists $data->{'metrics'}{'test'}{'bar'}, 'test metric exists in response');
        ok(exists $data->{'metrics'}{'xyzzy'},       'test metric exists in response');

        cmp_ok($data->{'metrics'}{'test'}{'foo'}, '==', 50,  'expected value of metric found');
        cmp_ok($data->{'metrics'}{'test'}{'bar'}, '==', 200, 'expected value of metric found');
        cmp_ok($data->{'metrics'}{'xyzzy'},       'eq', 'Nothing happens.', 'expected value of metric found');
    },
    host => '127.0.0.1',
    port => 8200,
);


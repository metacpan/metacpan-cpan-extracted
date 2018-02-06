#!perl

use Test::Most;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;

use lib "t/lib";
use MockStatsd;

my $stats = MockStatsd->new;

my @logs;

my $handler = builder {

    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{'psgix.logger'} = sub { push @logs, shift };
            return $app->($env);
        };
    };

    enable "Statsd", client => $stats;
    enable "ContentLength";
    enable "Head";

    sub {
        my $env    = shift;
        my $client = $env->{'psgix.monitor.statsd'};
        return [
            $client ? 200 : 500,
            [ 'Content-Type' => 'text/plain; charset=utf8' ], ['Ok']
        ];
    };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'head' => sub {

        my $req = HEAD '/';
        my $res = $cb->($req);

        is $res->code, 200, join( " ", $req->method, $req->uri );

        my @metrics = $stats->reset;

        cmp_deeply \@metrics,
          bag(
            [ 'timing_ms', 'psgi.response.time',           ignore(), ],
            [ 'timing_ms', 'psgi.request.content-length',  0, ],
            [ 'increment', 'psgi.request.method.HEAD', ],
            [ 'set_add',   'psgi.request.remote_addr',     '127.0.0.1', ],
            [ 'timing_ms', 'psgi.response.content-length', 0, ],
            [ 'increment', 'psgi.response.content-type.text.plain', ],
            [ 'increment', 'psgi.response.status.200', ],
          ),
          'expected metrics'
          or note( explain \@metrics );

        is_deeply \@logs, [], 'nothing logged';

    };

    subtest 'head' => sub {

        my $req = HEAD '/';
        my $res = $cb->($req);

        is $res->code, 200, join( " ", $req->method, $req->uri );

        my @metrics = $stats->reset;

        cmp_deeply \@metrics,
          bag(
            [ 'timing_ms', 'psgi.response.time',           ignore(), ],
            [ 'timing_ms', 'psgi.request.content-length',  0, ],
            [ 'increment', 'psgi.request.method.HEAD', ],
            [ 'set_add',   'psgi.request.remote_addr',     '127.0.0.1', ],
            [ 'timing_ms', 'psgi.response.content-length', 0, ],
            [ 'increment', 'psgi.response.content-type.text.plain', ],
            [ 'increment', 'psgi.response.status.200', ],
          ),
          'expected metrics'
          or note( explain \@metrics );

        is_deeply \@logs, [], 'nothing logged';

    };

    subtest 'errors' => sub {

        my $req = POST '/',
          Content_Type => 'text/x-something',
          Content      => "Some data";

        my $res = $cb->($req);

        is $res->code, 200, join( " ", $req->method, $req->uri );

        my @metrics = $stats->reset;

        cmp_deeply \@metrics, bag(
            [ 'timing_ms', 'psgi.response.time',          ignore(), ],
            [ 'timing_ms', 'psgi.request.content-length', 9, ],
            [ 'increment', 'psgi.request.content-type.text.x-something', ],

            # Note: the mock class throws an error so no method is logged
            [ 'set_add',   'psgi.request.remote_addr',     '127.0.0.1', ],
            [ 'timing_ms', 'psgi.response.content-length', 2, ],
            [ 'increment', 'psgi.response.content-type.text.plain', ],
            [ 'increment', 'psgi.response.status.200', ],
          ),
          'expected metrics'
          or note( explain \@metrics );

        cmp_deeply \@logs,
          [
            {
                level   => 'error',
                message => re('^Error at t/lib/MockStatsd\.pm line \d+'),
            }
          ],
          'errors logged'
          or note( explain \@logs );

    };

  };

done_testing;

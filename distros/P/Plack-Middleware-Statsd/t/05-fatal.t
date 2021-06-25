#!perl

use Test::Most;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::MIME;
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

    enable "Statsd", client  => $stats, catch_errors => 1;
    enable "ContentLength";
    enable "Head";

    sub {
        die "Fatal Error";
    };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'head (favicon.ico)' => sub {

        my $req = GET '/';
        my $res = $cb->($req);

        is $res->code, 500, join( " ", $req->method, $req->uri );

        my @metrics = $stats->reset;

        cmp_deeply \@metrics,
          bag(
            [ 'timing_ms', 'psgi.response.time',           ignore(), ],
            [ 'timing_ms', 'psgi.request.content-length',  0, ],
            [ 'increment', 'psgi.request.method.GET', ],
            [ 'timing_ms', 'psgi.response.content-length', ignore() ],
            [ 'increment', 'psgi.response.status.500', ],
            [ 'increment', 'psgi.response.content-type.text.plain', ],
            [ 'set_add',   'psgi.request.remote_addr', ignore() ],
            [ 'set_add',   'psgi.worker.pid', ignore() ],
          ),
          'expected metrics'
          or note( explain \@metrics );

        cmp_deeply \@logs,
          bag(
            {
                level   => 'error',
                message => re('Fatal Error'),
            },
          ),
          'expected errors logged'
          or note( explain \@logs );

    };

  };

done_testing;

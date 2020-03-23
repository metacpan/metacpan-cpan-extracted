#!perl

use Test::Most;

use HTTP::Request::Common;
use Plack::Builder;
use Plack::MIME;
use Plack::Test;

use lib "t/lib";
use MockStatsd;

{
    no warnings 'redefine';
    *MockStatsd::set_add = sub { die "Ouch " . $_[1] };
}

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

    enable "Statsd", client  => $stats;
    enable "ContentLength";
    enable "Head";

    sub {
        my $env    = shift;
        my $path   = $env->{PATH_INFO};
        my $type   = Plack::MIME->mime_type($path);
        my $client = $env->{'psgix.monitor.statsd'};
        return [
            $client ? 200 : 500,
            [ 'Content-Type' => $type || 'text/plain; charset=utf8' ], ['Ok']
        ];
    };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'head (favicon.ico)' => sub {

        my $req = HEAD '/favicon.ico';
        my $res = $cb->($req);

        is $res->code, 200, join( " ", $req->method, $req->uri );

        my @metrics = $stats->reset;

        cmp_deeply \@metrics,
          bag(
            [ 'timing_ms', 'psgi.response.time',           ignore(), ],
            [ 'timing_ms', 'psgi.request.content-length',  0, ],
            [ 'increment', 'psgi.request.method.HEAD', ],
            [ 'timing_ms', 'psgi.response.content-length', 0, ],
            [ 'increment', 'psgi.response.content-type.image.vnd-microsoft-icon', ],
            [ 'increment', 'psgi.response.status.200', ],
          ),
          'expected metrics'
          or note( explain \@metrics );

        cmp_deeply \@logs,
          bag(
            {
                level   => 'error',
                message => re('Ouch psgi\.request\.remote_addr'),
            },
            {
                level   => 'error',
                message => re('Ouch psgi\.worker.pid'),
            }
          ),
          'expected errors logged'
          or note( explain \@logs );

    };

  };

done_testing;

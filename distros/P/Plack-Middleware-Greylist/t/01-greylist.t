use v5.12;
use warnings;

use Test2::V0;

use HTTP::Request::Common;
use HTTP::Status qw/ :constants status_message /;
use Path::Tiny;
use Plack::Builder;
use Plack::Response;
use Plack::Test;
use Plack::Middleware::ReverseProxy;

my $file = Path::Tiny->tempfile;

my %greylist = (
    "172.16.1.0/24"  => "whitelist",
    "172.16.0.0/24"  => "5 netblock",    # rate limit entire netblock
    "107.20.0.0/14"  => [ 3, "ip" ],
    "13.64.0.0/11"   => 0,               # block
    "13.96.0.0/13"   => "5 msft",        # group multiple blocks
    "13.104.0.0/14"  => "5 msft",
    "66.249.64.0/19" => [ 10, ],         # higher than default limit\n"
);

my @logs;

my $handler = builder {

    # Capture log messages
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            $env->{'psgix.logger'} = sub {
                push @logs, $_[0];
            };
            return $app->($env);
        };
    };

    # Trust the "X-Forwarded-For" header
    enable "ReverseProxy";

    enable "Greylist",
      default_rate => 5,
      retry_after  => 120,
      file         => $file,
      cache_config => { init_file => 1, unlink_on_exit => 1 },
      greylist     => \%greylist;

    sub {
        my ($env) = @_;
        my $res = Plack::Response->new( HTTP_OK, [ 'Content-Type' => 'text/plain' ], [ status_message(HTTP_OK) ] );
        return $res->finalize;
    }
};

subtest "rate limiting" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $req = HEAD "/";

        for ( 1 .. 5 ) {
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is \@logs, [ { level => "warn", message => "Rate limiting 127.0.0.1 after 6/5 for default" } ], "logs";

        is $res->header('Retry-After'), 120, "Retry-After";

      SKIP: {
          skip "RELEASE_TESTING" unless $ENV{RELEASE_TESTING};

          # Even though Retry-After is larger, it's not enforced.
          sleep(61);
          my $res = $cb->($req);
          is $res->code, HTTP_OK, "request ok after delay";
        }

      };

};

subtest "rate limiting (netblock)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        for my $suff ( 1 .. 5 ) {
            my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.${suff}";
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.10";
        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is \@logs, [ { level => "warn", message => "Rate limiting 172.16.0.10 after 6/5 for 172.16.0.0/24" } ], "logs";

      };

};


subtest "rate limiting (shared blocks)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        for my $suff ( 1 .. 5 ) {
            my $req = HEAD "/", "X-Forwarded-For" => "13.96.0.${suff}";
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        my $req = HEAD "/", "X-Forwarded-For" => "13.104.0.1";
        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is \@logs, [ { level => "warn", message => "Rate limiting 13.104.0.1 after 6/5 for 13.104.0.0/14" } ], "logs";

      };

};


subtest "whitelisted" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $req = HEAD "/", "X-Forwarded-For" => "172.16.1.1";

        for ( 1 .. 6 ) {
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        is \@logs, [], "no warnings logged";

      };

};

subtest "greylist (lower limit)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $req = HEAD "/", "X-Forwarded-For" => "107.20.17.110";

        for ( 1 .. 3 ) {
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        {
            my $res = $cb->($req);
            is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";
        }

        is \@logs, [ { level => "warn", message => "Rate limiting 107.20.17.110 after 4/3 for 107.20.0.0/14" } ], "logs";

        {
            my $res = $cb->( HEAD "/", "X-Forwarded-For" => "107.20.17.111" );
            is $res->code, HTTP_OK, "request ok (different IP in same block)";
        }

      };

};

subtest "greylist (blocked)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $req = HEAD "/", "X-Forwarded-For" => "13.67.224.13";

        for ( 1 .. 2 ) {
            my $res = $cb->($req);
            is $res->code, HTTP_FORBIDDEN, "forbidden";
        }

        is \@logs,
          [
            { level => "warn", message => "Rate limiting 13.67.224.13 after 1/0 for 13.64.0.0/11" },
            { level => "warn", message => "Rate limiting 13.67.224.13 after 2/0 for 13.64.0.0/11" },
          ],
          "logs";

      };

};

subtest "greylist (higher limit)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $req = HEAD "/", "X-Forwarded-For" => "66.249.64.1";

        for ( 1 .. 10 ) {
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is \@logs, [ { level => "warn", message => "Rate limiting 66.249.64.1 after 11/10 for 66.249.64.0/19" } ], "logs";

      };

};

done_testing;

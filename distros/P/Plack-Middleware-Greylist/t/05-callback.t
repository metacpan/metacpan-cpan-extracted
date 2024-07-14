use v5.20;
use warnings;

use Test2::V0;
use Test2::Tools::Compare;

use HTTP::Request::Common;
use HTTP::Status qw/ :constants status_message /;
use Path::Tiny;
use Plack::Builder;
use Plack::Response;
use Plack::Test;
use Plack::Middleware::ReverseProxy;

use experimental qw/ signatures /;

my $file = Path::Tiny->tempfile;

my %greylist = ( "172.16.0.0/24" => [ 5, "netblock" ], );

my @logs;
my @calls;

my $handler = builder {

    # Capture log messages
    enable sub($app) {
        sub($env) {
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
      cache_config => {
        init_file      => 1,
        unlink_on_exit => 1,
        expire_time    => 30,
        share_file     => $file,
      },
      greylist => \%greylist,
      callback => sub {
        return 0 if $_[0]->{env}{REQUEST_URI} eq "/?ok";
        push @calls, $_[0];
        return 1;
      };

    sub($env) {
        my $res = Plack::Response->new( HTTP_OK, [ 'Content-Type' => 'text/plain' ], [ status_message(HTTP_OK) ] );
        return $res->finalize;
    }
};

subtest "rate limiting" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub($cb) {

        for my $suff ( 1 .. 5 ) {
            my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.${suff}";
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        {
            my $req = HEAD "/?ok", "X-Forwarded-For" => "172.16.0.10";
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok (callback override)";
        }

        my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.10";
        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is $res->header('Retry-After'), 31, "Retry-After set from expire_time";

        is \@logs, [], "nothing logged";

        is \@calls, [
            hash(
                sub {
                    field block   => "172.16.0.0/24";
                    field ip      => "172.16.0.10";
                    field hits    => 7;
                    field rate    => 5;
                    field message => "Rate limiting 172.16.0.10 after 7/5 for 172.16.0.0/24";
                    field env => hash(
                        sub {
                            field REMOTE_ADDR => "172.16.0.10";
                            etc;
                        }
                    );

                }
            )
          ],
          "callbacks";

      };

};

done_testing;

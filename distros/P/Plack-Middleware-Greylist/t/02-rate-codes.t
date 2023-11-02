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
    "172.16.1.0/24"  => "allowed",
    "13.64.0.0/11"   => "rejected",
    "66.249.64.0/19" => "norobots",
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
      greylist     => \%greylist;

    sub {
        my ($env) = @_;
        my $res = Plack::Response->new( HTTP_OK, [ 'Content-Type' => 'text/plain' ], [ status_message(HTTP_OK) ] );
        return $res->finalize;
    }
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

subtest "greylist (blocked)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $ip = "66.249.66.1";

        subtest "robots.txt" => sub {
            {
                my $req = GET "/robots.txt", "X-Forwarded-For" => $ip;
                my $res = $cb->($req);
                is $res->code, HTTP_OK, "allowed";
            }
        };

        subtest "blocked" => sub {

            my $req = GET "/", "X-Forwarded-For" => $ip;
            my $res = $cb->($req);
            is $res->code, HTTP_FORBIDDEN, "forbidden";

            # Note that this is counting the /robots.txt request
            is \@logs, [ { level => "warn", message => "Rate limiting ${ip} after 2/0 for 66.249.64.0/19" }, ], "logs";

        };

        subtest "robots.txt" => sub {
            {
                my $req = GET "/robots.txt", "X-Forwarded-For" => $ip;
                my $res = $cb->($req);
                is $res->code, HTTP_OK, "allowed";
            }
        };

      };

};

done_testing;

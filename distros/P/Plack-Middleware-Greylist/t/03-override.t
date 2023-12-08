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
    "172.16.0.0/24"   => [ 5,  "netblock" ],
    "172.16.0.128/32" => [ 10, "ip" ],         # override
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
      cache_config => {
        init_file      => 1,
        unlink_on_exit => 1,
        expire_time    => 30,
        share_file     => $file,
      },
      greylist => \%greylist;

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

        for my $suff ( 1 .. 5 ) {
            my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.${suff}";
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.10";
        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is $res->header('Retry-After'), 31, "Retry-After set from expire_time";

        is \@logs, [ { level => "warn", message => "Rate limiting 172.16.0.10 after 6/5 for 172.16.0.0/24" } ], "logs";

      };

};

subtest "greylist (higher limit)" => sub {

    @logs = ();

    test_psgi
      app    => $handler,
      client => sub {
        my $cb = shift;

        my $req = HEAD "/", "X-Forwarded-For" => "172.16.0.128";

        for ( 1 .. 10 ) {
            my $res = $cb->($req);
            is $res->code, HTTP_OK, "request ok";
        }

        my $res = $cb->($req);
        is $res->code, HTTP_TOO_MANY_REQUESTS, "too many requests";

        is \@logs, [ { level => "warn", message => "Rate limiting 172.16.0.128 after 11/10 for 172.16.0.128/32" } ], "logs";

      };

};

done_testing;

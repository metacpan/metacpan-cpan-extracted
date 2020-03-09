#!perl

use strict;
use warnings;

use Test::More;

use HTTP::Status qw/ :constants :is /;
use HTTP::Request::Common;
use Log::Dispatch 2.68;
use Log::Dispatch::Array;
use Plack::Builder;
use Plack::Test;

my @events;


my $log = Log::Dispatch->new;
$log->add(
    Log::Dispatch::Array->new(
        name      => 'test',
        min_level => 'debug',
        array     => \@events,
    )
);

my $handler = builder {

    enable "LogDispatch", logger => $log;

    enable "Security::Simple",
        rules => [
            PATH_INFO => qr{\.(php|asp)$},
            -and => {
                PATH_INFO      => qr{^/cgi-bin/},
                REQUEST_METHOD => "POST",
            }
        ];

    sub { return [ HTTP_OK, [], ['Ok'] ] };
};

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    subtest 'not blocked' => sub {
        my $req = GET "/some/thing.html";
        my $res = $cb->($req);

        ok is_success( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_OK, "HTTP_OK";

        is_deeply \@events, [], 'nothing logged';

    };

    subtest 'blocked' => sub {
        my $req = GET "/some/thing.php";
        my $res = $cb->($req);

        ok is_error( $res->code ), join( " ", $req->method, $req->uri );
        is $res->code, HTTP_BAD_REQUEST, "HTTP_BAD_REQUEST";

        is_deeply \@events,
          [
            {
                level => 'warn',
                message => 'Plack::Middleware::Security::Simple Blocked 127.0.0.1 /some/thing.php',
            }
          ],
          'nothing logged';

    };

 };

done_testing;

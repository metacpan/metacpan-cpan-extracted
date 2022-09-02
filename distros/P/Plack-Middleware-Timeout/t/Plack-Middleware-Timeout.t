use strict;
use warnings;

use Plack::Middleware::Timeout;
use Test::More tests => 12;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Status qw(HTTP_GATEWAY_TIMEOUT);

my $app = sub { sleep 2; return [ 200, [], ["Hello"] ] };
my $timeout_app = sub { sleep 5; return [ 200, [], "Hello" ] };
my $blow_up = sub { die "kaboom!" };

{
    my $app = Plack::Middleware::Timeout->wrap( $app, timeout => 4, soft_timeout => 1 );
    my $warning_caught;
    local $SIG{__WARN__} = sub { ($warning_caught) = @_; };

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );
        is $res->code, 200, "response looks ok";

        like $warning_caught, qr/Soft timeout reached/,
          'warning caught matches the default warning';
    };
}

{
    my $timeout_app = Plack::Middleware::Timeout->wrap(
        $timeout_app,
        timeout  => 4,
        response => sub {
            my $plack_response = shift;
            $plack_response->body('the request timed out');
            return $plack_response;
        },
    );

    diag("waiting for the timeout alarm() to trigger...");

    test_psgi $timeout_app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );
        is $res->code, HTTP_GATEWAY_TIMEOUT, "response code ok";
        is $res->content, "the request timed out", 'response body looks ok';
    };

}

{
    my $timeout_app =
      Plack::Middleware::Timeout->wrap( $timeout_app, timeout => 4 );

    my $warning_caught;
    local $SIG{__WARN__} = sub { ($warning_caught) = @_; };

    diag("waiting for the timeout alarm() to trigger...");

    test_psgi $timeout_app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );
        is $res->code, HTTP_GATEWAY_TIMEOUT, "response code ok";
        like $warning_caught, qr/due to timeout \(\d+s\)/,
          'warning caught matches the default warning';
    };
}

{
    #  no timeout reached, no soft timeout reached
    my $app = Plack::Middleware::Timeout->wrap($app, timeout => 4, soft_timeout => 3 );
    my $warning_caught = undef;
    local $SIG{__WARN__} = sub { ($warning_caught) = @_; };

    test_psgi $app => sub {
        my $cb = shift;
        my $res = $cb->( GET "/" );
        is $res->code, 200, "response looks ok";
        is $res->decoded_content, "Hello", "response body looks ok";

        is($warning_caught, undef, "no warning was emitted");
    };
}

{
    my $app = Plack::Middleware::Timeout->wrap($blow_up, timeout => 4, soft_timeout => 3 );
    my $warning_caught = undef;
    local $SIG{__WARN__} = sub { ($warning_caught) = @_; };
    test_psgi $app => sub {
        my $cb = shift;
        my $res = $cb->( GET "/" );
        is $res->code, 500, "response looks ok";
        is ($res->decoded_content, "kaboom! at t/Plack-Middleware-Timeout.t line 12.\n", "response body looks ok");

        is($warning_caught, undef, "no warning was emitted");
    };
}

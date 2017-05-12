use strict;
use warnings;

use Plack::Middleware::Timeout;
use Plack::Test;
use HTTP::Request::Common;
use Test::More tests => 4;
use Time::HiRes qw(time);

my $app = sub { sleep 121; return [ 200, [], ["Hello"] ] };

SKIP :{
    skip "author tests skipped", 4, unless $ENV{TEST_AUTHOR};

    my $app = Plack::Middleware::Timeout->wrap( $app );
    my $warning_caught;
    local $SIG{__WARN__} = sub { ($warning_caught) = @_; };

    diag("waiting for 120s to capture the default timeout value");

    test_psgi $app, sub {
        my $cb  = shift;

        my $time_started = time();
        my $res = $cb->( GET "/" );
        my $time_now = time();
        cmp_ok($time_now - $time_started, ">", 120, "timeout ok");
        cmp_ok($time_now - $time_started, "<", 121, "timeout ok");
        
        is $res->code, 408, "response looks ok";

        like $warning_caught, qr/Terminated request for uri/,
          'warning caught matches the default warning';
    };
}

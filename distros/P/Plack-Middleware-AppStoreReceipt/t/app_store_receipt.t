use strict;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::AppStoreReceipt;
use Test::More;

BEGIN {
    plan skip_all => "Set TEST_LIVE environment variable to run live tests." if !$ENV{TEST_LIVE};
}

my $app = sub {};
$app = Plack::Middleware::AppStoreReceipt->wrap( $app );

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->( POST "/receipts/validate" );
    is( $res->code, 200, "a valid method" );
    my $res = $cb->( GET "/receipts/validate" );
    is( $res->code, 405, "an invalid method" );
};

done_testing;

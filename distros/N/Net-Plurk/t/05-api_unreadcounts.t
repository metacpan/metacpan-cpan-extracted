#!perl -T

use Env qw(CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET);
use Test::More;
if ($CONSUMER_KEY and $CONSUMER_SECRET 
    and $ACCESS_TOKEN and $ACCESS_TOKEN_SECRET) {
    plan tests => 5;
} else {
    plan skip_all =>
    "You must set the following environment variables: \n".
    "CONSUMER_KEY/CONSUMER_SECRET\n".
    "ACCESS_TOKEN/ACCESS_TOKEN_SECRET\n";
}

BEGIN {
	use Net::Plurk;
	my $key = $CONSUMER_KEY;
	my $secret = $CONSUMER_SECRET;
	my $token = $ACCESS_TOKEN;
	my $token_secret = $ACCESS_TOKEN_SECRET;
	my $p = Net::Plurk->new(consumer_key => $key, consumer_secret => $secret);
	$p->authorize(token => $token, token_secret => $token_secret);
        my $json = $p->callAPI( '/Polling/getUnreadCount');
        isa_ok ($json, HASH);
        cmp_ok( $json->{all}, '>=', 0);
        cmp_ok( $json->{my}, '>=', 0);
        cmp_ok( $json->{private}, '>=', 0);
        cmp_ok( $json->{responded}, '>=', 0);
}

diag( "Testing using API to retrieve unReadCount directly" );

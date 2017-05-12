#!perl -T

use Env qw(CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET);
use Test::More;
if ($CONSUMER_KEY and $CONSUMER_SECRET 
    and $ACCESS_TOKEN and $ACCESS_TOKEN_SECRET) {
    plan tests => 3
} else {
    plan skip_all =>
    "You must set the following environment variables: \n".
    "CONSUMER_KEY/CONSUMER_SECRET\n".
    "ACCESS_TOKEN/ACCESS_TOKEN_SECRET\n";
}

BEGIN {
	use Net::Plurk;
	my $p = Net::Plurk->new(consumer_key => $CONSUMER_KEY, consumer_secret => $CONSUMER_SECRET);
	$p->authorize(token => $ACCESS_TOKEN, token_secret => $ACCESS_TOKEN_SECRET);
        is($p->follow('plurkpl'), 1);
	is($p->errorcode, 0);
	is($p->errormsg, undef);
}

diag( "Testing Be My fan ");

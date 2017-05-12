#!perl -T

use Env qw(CONSUMER_KEY CONSUMER_SECRET ACCESS_TOKEN ACCESS_TOKEN_SECRET);
use Test::More;
if ($CONSUMER_KEY and $CONSUMER_SECRET 
    and $ACCESS_TOKEN and $ACCESS_TOKEN_SECRET) {
    plan tests => 3;
} else {
    plan skip_all =>
    "You must set the following environment variables: \n".
    "CONSUMER_KEY/CONSUMER_SECRET\n".
    "ACCESS_TOKEN/ACCESS_TOKEN_SECRET\n";
}

BEGIN {
	use Net::Plurk;
	use Net::Plurk::UserProfile;
	use Net::Plurk::User;
	my $key = $CONSUMER_KEY;
	my $secret = $CONSUMER_SECRET;
	my $token = $ACCESS_TOKEN;
	my $token_secret = $ACCESS_TOKEN_SECRET;
	my $p = Net::Plurk->new(consumer_key => $key, consumer_secret => $secret);
	$p->authorize(token => $token, token_secret => $token_secret);
        my $profile = $p->get_own_profile();
        isa_ok ($profile, Net::Plurk::UserProfile);
        isa_ok ($profile->user_info, Net::Plurk::User);
	$p->raw_output(1);
        $profile = $p->get_own_profile();
	isa_ok ($profile, 'HASH');
}

diag( "Testing Net::Plurk Check user page" );

#!perl -T

use Env qw(CONSUMER_KEY CONSUMER_SECRET);
use Test::More;
if ($CONSUMER_KEY and $CONSUMER_SECRET) {
    plan tests => 2;
} else {
    plan skip_all =>
    'You must set environment variable: CONSUMER_KEY/CONSUMER_SECRET';
}

BEGIN {
	use Net::Plurk;
	use Net::Plurk::UserProfile;
	use Net::Plurk::User;
	my $key = $CONSUMER_KEY;
	my $secret = $CONSUMER_SECRET;
	my $p = Net::Plurk->new(consumer_key => $key, consumer_secret => $secret);
        my $profile = $p->get_public_profile ( 'clsung' );
        isa_ok ($profile, Net::Plurk::PublicUserProfile);
        isa_ok ($profile->user_info, Net::Plurk::User);
}

diag( "Testing Get Public User Profile" );

#!perl -T

use Env qw(CONSUMER_KEY CONSUMER_SECRET);
use Test::More;
if ($CONSUMER_KEY and $CONSUMER_SECRET) {
    plan tests => 4;
} else {
    plan skip_all =>
    'You must set environment variable: CONSUMER_KEY/CONSUMER_SECRET';
}

BEGIN {
	use_ok( 'Net::Plurk' );
	my $key = $CONSUMER_KEY;
	my $secret = $CONSUMER_SECRET;
	my $p = Net::Plurk->new(consumer_key => $key, consumer_secret => $secret);
	$p->raw_output(1);
	my $r = $p->get_public_profile('clsung');
        is ($p->errormsg, undef);
        is ($p->errorcode, 0);
	is ($r->{user_info}->{full_name}, 'Cheng-Lung Sung'); # Author's Name :)
}

diag( "Testing Net::Plurk Basic Usage" );

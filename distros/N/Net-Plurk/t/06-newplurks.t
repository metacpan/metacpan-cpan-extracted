#!perl -T

use Test::More tests => 2;
use Env qw(PLURKAPIKEY PLURKUSER PLURKPASS);

BEGIN {
	use Net::Plurk;
	use Net::Plurk::Plurk;
        my $api_key = $PLURKAPIKEY // "dKkIdUCoHo7vUDPjd3zE0bRvdm5a9sQi";
        my $user = $PLURKUSER // 'nobody';
        my $pass = $PLURKPASS // 'nopass';
        my $p = Net::Plurk->new(api_key => $api_key);
        $p->login(user => $user, pass => $pass );
        is(1, $p->is_logged_in());
        my $plurks = $p->get_new_plurks(limit => 1);
        my $plurk = Net::Plurk::Plurk->new($plurks->[0]);
        isa_ok ($plurk, Net::Plurk::Plurk);
}

diag( "Testing Net::Plurk polling new plurks" );

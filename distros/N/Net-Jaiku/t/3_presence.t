use Test::More tests => 6;
use Net::Jaiku;

SKIP: {
	skip "Please set environment variables JAIKU_USER and JAIKU_KEY to run these tests", 6
		unless $ENV{JAIKU_USER} && $ENV{JAIKU_KEY};

	$jaiku = Net::Jaiku->new(
		username => $ENV{JAIKU_USER},
		userkey  => $ENV{JAIKU_KEY}
	);

	$rv = $jaiku->getUserPresence(user => 'merlyn');
	ok( $rv->title );
	ok( $rv->user->nick eq 'merlyn' );
	ok( lc $rv->user->url eq lc 'http://merlyn.jaiku.com' );

	my $rv = $jaiku->getMyPresence;
	ok( $rv->title );
	ok( $rv->user->nick eq $jaiku->username );
	ok( lc $rv->user->url eq lc 'http://'.$jaiku->username.'.jaiku.com' );

}

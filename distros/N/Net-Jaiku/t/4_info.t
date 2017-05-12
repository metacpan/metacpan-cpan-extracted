use Test::More tests => 4;
use Net::Jaiku;

SKIP: {
#	skip "API returns blank values right now", 4;
	skip "Please set environment variables JAIKU_USER and JAIKU_KEY to run these tests", 4
		unless $ENV{JAIKU_USER} && $ENV{JAIKU_KEY};

	$jaiku = Net::Jaiku->new(
		username => $ENV{JAIKU_USER},
		userkey  => $ENV{JAIKU_KEY}
	);

	$rv = $jaiku->getUserInfo( user => 'merlyn' );
	ok( $rv->nick eq 'merlyn' );
	ok( lc $rv->url eq lc 'http://merlyn.jaiku.com' );

	my $rv = $jaiku->getMyInfo;
	ok( $rv->nick eq $jaiku->username );
	ok( lc $rv->url eq lc 'http://'.$jaiku->username.'.jaiku.com' );

}

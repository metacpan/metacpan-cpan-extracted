use Test::More tests => 8;
use Net::Jaiku;
#use LWP::Debug qw(+ -conns);
use Data::Dumper;

$jaiku = Net::Jaiku->new(
	username => $ENV{JAIKU_USER} || '',
	userkey  => $ENV{JAIKU_KEY}  || ''
);

$rv = $jaiku->getFeed;
ok( @{ $rv->stream } > 0 );
ok( $rv->stream->[0]->id =~ /^\d+$/ );

SKIP: {
	skip "Please set environment variables JAIKU_USER and JAIKU_KEY to run these tests", 6
		unless $ENV{JAIKU_USER} && $ENV{JAIKU_KEY};

	$rv = $jaiku->getUserFeed( user => 'merlyn' );
	ok( @{ $rv->stream } > 0 );
	ok( $rv->stream->[0]->id =~ /^\d+$/ );

	$rv = $jaiku->getMyFeed;
	ok( @{ $rv->stream } > 0 );
	ok( $rv->stream->[0]->id =~ /^\d+$/ );

	$rv = $jaiku->getContactsFeed;
	ok( @{ $rv->stream } > 0 );
	my $id = $rv->stream->[0]->id || $rv->stream->[0]->comment_id;
	ok( $id =~ /^\d+$/ );

}

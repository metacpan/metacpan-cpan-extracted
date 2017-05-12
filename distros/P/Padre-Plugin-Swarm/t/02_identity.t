use Test::More 'no_plan';

BEGIN {
	use_ok( 'Padre::Swarm::Identity' );
	
};

my $id = Padre::Swarm::Identity->new(
	nickname => 'james-bond',
	service  => 'chat',
	transport=> 'multicast:239.255.1.1',
);
ok( $id->canonical , $id->canonical );

$id->set_service( 'editor' );
ok( $id->canonical , $id->canonical );

$id->set_resource( 'scope' );
ok( $id->canonical , $id->canonical );

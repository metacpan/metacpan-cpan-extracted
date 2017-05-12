use Test::More skip_all => 'Still trouble driving padre in testing';
use JSON;
use t::lib::Demo;

use threads;         # need to be loaded before Padre
use threads::shared; # need to be loaded before Padre
use Padre;
use Padre::Swarm::Message;
use Padre::Swarm::Service;
use IO::Socket::Multicast;
use Data::Dumper;
my $app = Padre->new;
isa_ok($app, 'Padre');


my $chat = Padre::Swarm::Service->new;
$chat->schedule;
my $socket = IO::Socket::Multicast->new;

my $got_loopback = 0; 
Wx::Event::EVT_COMMAND( $app->wx->main , -1 , $chat->event,
 sub { diag "LOOPBACK!" ; $got_loopback = 1 }
);
diag( "WX event is " . $chat->event );


$socket->mcast_send(
        JSON::encode_json( {
		from => getlogin(),
		type =>'chat',
		body => 'test',
	}) ,
	'239.255.255.1:12000',
);


ok( $got_loopback , 'got service event' );

$chat->shutdown;

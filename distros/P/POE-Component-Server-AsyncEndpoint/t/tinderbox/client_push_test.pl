
# send a message to the queue 'foo'
use Net::Stomp;

my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '61614' } );

$stomp->connect( { login => 'hello', passcode => 'there' } );
$stomp->send(
             { destination => '/queue/foo', body => 'test message' } );
$stomp->disconnect;


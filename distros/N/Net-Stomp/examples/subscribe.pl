#!perl
use strict;
use warnings;
use lib 'lib';
use Net::Stomp;

my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );
$stomp->connect( { login => 'hello', passcode => 'there' } );
$stomp->subscribe(
    {   destination             => '/queue/foo',
        'ack'                   => 'client',
        'activemq.prefetchSize' => 1,
    }
);

while ( $stomp->can_read( { timeout => 1 } ) ) {
    my $frame = $stomp->receive_frame;
    $stomp->ack( { frame => $frame } );
    warn $frame->command . ': >' . substr( $frame->body, 0, 80 ) . "<\n";
}

$stomp->disconnect;


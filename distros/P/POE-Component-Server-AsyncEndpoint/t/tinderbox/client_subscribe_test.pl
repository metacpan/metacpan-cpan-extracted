#!/usr/bin/perl

# subscribe to messages from the queue 'foo'
use Net::Stomp;
use Data::Dumper;
my $stomp = Net::Stomp->new( { hostname => '127.0.0.1', port => '61614' } );
$stomp->connect( { login => 'hello', passcode => 'there' } );
$stomp->subscribe(
		  {   destination             => '/queue/ob_censo_encuesta',
		      'ack'                   => 'client',
		      'activemq.prefetchSize' => 1
		      }
		  );
while (1) {
    my $frame = $stomp->receive_frame;
    print "GOT FRAME\n";
    #warn Dumper($frame->headers);
    warn $frame->body; # do something here
    $stomp->ack( { frame => $frame } );
}
$stomp->disconnect;

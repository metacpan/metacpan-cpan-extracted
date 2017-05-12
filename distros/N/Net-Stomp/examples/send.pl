#!perl
use strict;
use warnings;
use lib 'lib';
use DateTime;
use Net::Stomp;

my $stomp = Net::Stomp->new( { hostname => 'localhost', port => '61613' } );
$stomp->connect( { login => 'hello', passcode => 'there' } );

my $count = shift || 1;

foreach my $i ( 1 .. $count ) {
    warn $i;
    $stomp->send(
        {   destination   => '/queue/foo',
            body          => DateTime->now . " $i",
            bytes_message => 1,
        }
    );
}

$stomp->disconnect;

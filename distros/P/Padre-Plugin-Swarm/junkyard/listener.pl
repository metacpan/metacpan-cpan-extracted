#!/usr/bin/perl
use lib qw( lib );
use Data::Dumper;

$|++;

use Padre::Swarm::Transport::Multicast;
my $mc = Padre::Swarm::Transport::Multicast->new;
$mc->subscribe_channel( 12000 );
$mc->subscribe_channel( 13000 );
$mc->start;

while ( 1 ) {
	my ($channel) = $mc->poll(1);
	next unless $channel;
	my $buffer;
	my ($message,$frame) = $mc->receive_from_channel( $channel  );
	print Dumper $frame;
	print Dumper $message;
}

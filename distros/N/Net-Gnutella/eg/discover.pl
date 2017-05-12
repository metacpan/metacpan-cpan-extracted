#!/usr/bin/perl
use Net::Gnutella;
use strict;

my $gnutella = Net::Gnutella->new;

$gnutella->add_handler("pong", \&on_pong);
$gnutella->add_handler("disconnect", \&on_disconnect);

my $client = $gnutella->new_client(
	Server => "gnutellahosts.com",
);

$gnutella->do_one_loop while $client->is_outgoing;

$client->send_packet(new Net::Gnutella::Packet::Ping);

$gnutella->start;

sub on_pong {
	my ($self, $event) = @_;

	printf "%s:%d\n", $event->packet->ip_as_string, $event->packet->port;
}

sub on_disconnect {
	exit;
}

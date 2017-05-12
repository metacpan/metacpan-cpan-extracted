#!/usr/bin/perl
use Net::Gnutella;
use Benchmark;
use strict;

my $query   = $ARGV[0] || die "usage: $0 QUERY [ TIMEOUT ]\n";
my $timeout = $ARGV[1] || 20;
my $end = time() + $timeout;

my $gnutella = new Net::Gnutella;

my $client = $gnutella->new_client(
	Server  => "denis.habitue.net",
	Port    => 6346,
);

$gnutella->do_one_loop while $client->is_outgoing;

my $query = Net::Gnutella::Packet::Query->new(
	Query  => $query,
);

$client->send_packet($query);

$gnutella->add_handler("reply", \&on_reply);
$gnutella->add_handler("disconnect", \&on_disconnect);

$gnutella->start;

sub on_reply {
	my ($self, $event) = @_;

	my $packet = $event->packet;
	my $ip = $packet->ip_as_string;
	my $port = $packet->port;

	foreach my $result (@{ $packet->results }) {
		printf "http://%s:%d/get/%d/%s\n", $ip, $port, $result->[0], $result->[2];
	}
}

sub on_disconnect {
	exit;
}

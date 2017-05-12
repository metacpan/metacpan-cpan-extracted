#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use Net::Jabber::Loudmouth;

my %opts;
getopt('supmtnr', \%opts);

if (!$opts{s} || !$opts{m} || !$opts{t} || !$opts{u} || !$opts{p}) {
	print "Usage: $0 -s <server> -u <username> -p <password> -m <message> -t <recipient> [--n <port>] [-r <resource>]\n";
	exit 1;
}

{ no warnings 'once';
$opts{n} ||= $Net::Jaber::Loudmouth::DefaultPort; }
$opts{r} ||= 'jabber-send';

my $connection = Net::Jabber::Loudmouth::Connection->new($opts{s});
$connection->open_and_block();
$connection->authenticate_and_block($opts{u}, $opts{p}, $opts{r});

my $m = Net::Jabber::Loudmouth::Message->new($opts{t}, 'message');
$m->get_node->add_child('body', $opts{m});

$connection->send($m);

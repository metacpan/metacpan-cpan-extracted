#!/usr/bin/perl

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Getopt::Std;
use Net::Jabber::Loudmouth;

my %opts;
getopt('supmtnr', \%opts);

if (!$opts{s} || !$opts{m} || !$opts{t} || !$opts{u} || !$opts{p}) {
	print STDERR "Usage: $0 -s <server> -u <username> -p <password> -m <message> -t <recipient> [--n <port>] [-r <resource>]\n";
	exit 1;
}

{ no warnings 'once';
$opts{n} ||= $Net::Jaber::Loudmouth::DefaultPort; }
$opts{r} ||= 'jabber-send';

my $context = Glib::MainContext->new();
my $connection = Net::Jabber::Loudmouth::Connection->new_with_context($opts{s}, $context);

my $msg_data = {
	recipient	=> $opts{t},
	message		=> $opts{m}
};

my $connection_data = {
	username	=> $opts{u},
	password	=> $opts{p},
	resource	=> $opts{r},
	msg_data	=> $msg_data
};

$connection->open(\&connection_open_result_cb, $connection_data);

my $main_loop = Glib::MainLoop->new($context, FALSE);
$main_loop->run();

sub connection_open_result_cb {
	my ($connection, $success, $data) = @_;

	unless ($success) {
		print STDERR "Connection failed\n";
		exit 2;
	}

	$connection->authenticate($data->{username}, $data->{password}, $data->{resource}, \&connection_auth_cb, $data->{msg_data});
}

sub connection_auth_cb {
	my ($connection, $success, $data) = @_;

	unless ($success) {
		print STDERR "Authentication failed\n";
		exit 3;
	}

	my $m = Net::Jabber::Loudmouth::Message->new($data->{recipient}, 'message');
	$m->get_node->add_child('body', $data->{message});

	unless ($connection->send($m)) {
		print STDERR "Send failed\n";
		exit 4;
	}

	$connection->close();
	$main_loop->quit();
}

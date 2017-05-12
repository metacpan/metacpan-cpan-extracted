use strict;
use Net::Jabber qw(Server);
use Net::Jabber::Server;

sub start_server {
	my $pid = fork();
	die "can't fork" unless defined $pid;

	unless ($pid) {
#		my $server = Net::Jabber::Server->new();
#		$server->Start();
		exit;
	}

#	sleep 1; #wait for the server to start
}

1;

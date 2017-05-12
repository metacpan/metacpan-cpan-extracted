use strict;
use HTTP::Proxy;

sub start_proxy {

	my $pid = fork();
	die "fork failed" unless defined $pid;

	unless ($pid) {
		my $proxy = HTTP::Proxy->new(port => 4143);
		$proxy->start();
		exit;
	}

	return $pid;
}

1;

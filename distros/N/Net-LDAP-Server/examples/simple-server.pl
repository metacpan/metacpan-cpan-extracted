#!/usr/bin/perl

use strict;
use warnings;

use IO::Select;
use IO::Socket;
use MyDemoServer;

my $sock = IO::Socket::INET->new(
	Listen => 5,
	Proto => 'tcp',
	Reuse => 1,
	LocalPort => 8080
);

my $sel = IO::Select->new($sock);
my %Handlers;
while (my @ready = $sel->can_read) {
	foreach my $fh (@ready) {
		if ($fh == $sock) {
			# let's create a new socket
			my $psock = $sock->accept;
			$sel->add($psock);
			$Handlers{*$psock} = MyDemoServer->new($psock);
		} else {
			my $result = $Handlers{*$fh}->handle;
			if ($result) {
				# we have finished with the socket
				$sel->remove($fh);
				$fh->close;
				delete $Handlers{*$fh};
			}
		}
	}
}

1;

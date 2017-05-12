#!/usr/bin/perl

use strict;
use POE::Declare::HTTP::Client ();

exit(255) unless $ARGV[0];

my $client = POE::Declare::HTTP::Client->new(
	Timeout       => 5,
	ResponseEvent => \&response,
	ShutdownEvent => \&shutdown,
);

# Startup, ping the server to let them know we are running
$client->start;
$client->GET($ARGV[0]);

my $response = 0;
sub response {
	if ( ++$response == 1 ) {
		# Upload the content file
		# print STDERR "# PUT $ARGV[0]response.xml\n";
		$client->PUT(
			"$ARGV[0]response.xml",
			Content => 'This is my response',
		);
		# print $_[1]->code . ' ' . $_[1]->message . "\n";
	} else {
		$client->stop;
	}
}

sub shutdown {
	sleep 1;
	exit(0);
}

POE::Kernel->run;

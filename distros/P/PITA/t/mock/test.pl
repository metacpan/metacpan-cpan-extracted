#!/usr/bin/perl

use strict;
use POE::Declare::HTTP::Client ();

exit(255) unless $ARGV[0];

# print STDERR "# STARTUP\n";
sleep 5;

my $client = POE::Declare::HTTP::Client->new(
	Timeout       => 5,
	ResponseEvent => \&response,
	ShutdownEvent => \&shutdown,
);

# Startup, ping the server to let them know we are running
$client->start;

# Ping
# print STDERR "# GET $ARGV[0]\n";
$client->GET($ARGV[0]);

my $response = 0;
sub response {
	if ( ++$response == 1 ) {
		# Fetch a CPAN module from the mirror
		# print STDERR "# GET $ARGV[0]cpan/Config-Tiny-2.13.tar.gz\n";
		$client->GET("$ARGV[0]cpan/Config-Tiny-2.13.tar.gz");

	} elsif ( $response == 2 ) {
		# Upload the content file
		# print STDERR "# PUT $ARGV[0]response.xml\n";
		$client->PUT(
			"$ARGV[0]response.xml",
			Content => 'This is my response',
		);

	} else {
		# print STDERR "# SHUTDOWN\n";
		sleep 5;
		$client->stop;
	}
}

sub shutdown {
	sleep 1;
	exit(0);
}

POE::Kernel->run;

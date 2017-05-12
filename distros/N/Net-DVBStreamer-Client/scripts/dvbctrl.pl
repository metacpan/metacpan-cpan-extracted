#!/usr/bin/perl -w

use Net::DVBStreamer::Client;
use Term::ReadLine;
use Getopt::Std;
use vars qw/ %opt /;
use Data::Dumper;
use strict;

$|=1;



# Parse options from the command line
getopts( "h:a:f:u:p:", \%opt ) or usage();


# Defaults for settings
my $host = $opt{h}		|| 'localhost';
my $adaptor = $opt{a}	|| 0;
my $username = $opt{u}	|| 'dvbstreamer';
my $password = $opt{p}	|| undef;
my $file = $opt{f}		|| undef;


# Connect to remote server
my $dvbs = new Net::DVBStreamer::Client( $host, $adaptor );

if (defined $username and defined $password) {
	if (!$dvbs->authenticate( $username, $password )) {
		die "Failed to authenticate with server: ".$dvbs->response()."\n";
	}
}


## Process commands from a file?
if (defined $file) {
	
	open( FILE, $file ) or die "Failed to open input file: $!";
	
	while( <FILE> ) {
		chomp();
		last if(my_send_command( $dvbs, $_ ));
	}
	
	close( FILE );


## Process command from command-line?
} elsif ( @ARGV ) {

	# Send command to server
	my_send_command( $dvbs, @ARGV );


## Process commands from STDIN
} else {

	# Create new terminal
	my $term = new Term::ReadLine 'PerlDVBCtrl';
	
	print "Connected to $host, adaptor $adaptor (server version ".$dvbs->server_version().").\n";
	
	# Read commands from the console
	while ( defined (my $cmd = $term->readline('PerlDVBCtrl>')) ) {
	
		# Trim whitespace
		chomp($cmd);
		
		# End of session?
		if ($cmd eq 'quit' or $cmd eq 'logout') {
			$dvbs->send_command( 'logout' );
			last;
		}
		
		# Send command to server
		my_send_command( $dvbs, $cmd );
	}
}


sub my_send_command {
	my $dvbs = shift;
	
	my (@result) = $dvbs->send_command( @_ );
	if (defined $result[0]) {
	
		# Success
		print join( "\n", @result )."\n";
		return 0;
		
	} else {
	
		# Error
		print "Error: ".$dvbs->response()."\n";
		return $dvbs->errno();
		
	}
}


sub usage {

	print "Usage: $0 [options] [command]\n\n";
	print "  -h host      Host to connect to (default localhost).\n";
	print "  -a adaptor   Adaptor on host to connect to (default 0).\n";
	print "  -f file      File to read list of commands from.\n";
	print "  -u username  Username to authenticate with (default 'dvbstreamer').\n";
	print "  -p password  Password to authenticate with.\n";
	print "\n";
	
	exit(-1);
}



#!/usr/bin/perl

## Usage: script.pl <text_file>

# This script is intended to simulate some of the quirks of the output of
# some TL1 gateways. It is not interactive, but the TL1ng module's parsing
# functionality can be tested using response data from a real interactive 
# session, saved in a text file. 

# Anything that looks funny or wrong in here is likely on purpose.

print "\n";

use IO::Socket;

my $sock = new IO::Socket::INET ( 
    LocalHost => '127.0.0.1',
    LocalPort => '12345',
    Proto => 'tcp',
    Listen => 1,
    Reuse => 1,
    ) || die "Could not create socket: $!\n";

print "Socket created, listening for client connection...\n";

my $client = $sock->accept();
$client->autoflush(1);
print "Client connected, sending data...\n\n";


## NOTE: Some TL1 streams use different line endings in different places.
## Why? I have no idea, but it seems like a good thing to test against, no?

READINPUT:
while(my $line = <>) {

    # If a line isn't empty, it's likely the first line of a TL1 message.
    # Clean it up and print it to the socket...
    chomp $line; 
    if (/^$/) {
    	print $client "$line\n"	
    } 
    else {
    	print $client "$line\015\012";	
    }

    # ..and keep doing that until you reach the end of the message.
    MSGLINE:     
    while (my $line = <>) { 
        chomp $line;
        if (/^$/) { 
        	print $client "$line\n"; 
        	last MSGLINE; 
        } 
        else {
        	print $client "$line\015\012";	
        }
    }
    
    # Then sleep a tiny bit... maybe
    my $sleepchance = 30; # % chance of sleeping.
    rand_short_sleep() if int(rand()*100) < $sleepchance; 
}

print "All data sent. Quitting.\n\n";


##############################################################################


# sleep for a random fraction of a second.
sub rand_short_sleep {
	my $yfact = int(rand() * 1000)/1000;
    my $xfact = int(rand() * 1000)/1000;
    my $sleep = int($xfact * $yfact * 100 - 10)/100;

    # select() can simulate sleeping for fractions of a second.
	# I chose using it because some people may not have the 
	# CPAN module for high-res sleep.
    select(undef, undef, undef, abs $sleep);
    return 1;
}

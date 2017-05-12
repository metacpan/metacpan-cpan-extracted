#!/usr/bin/perl

################################################################################
# Authors:      Brandon Casey (bcasey@cpan.org)
#               Anthony Lucillo (alucillo@cpan.org)
#
# Purpose:      An example simulation for the client of an sctp server
#               using the sctp module built using xs.
#
# Last Modified: February 28, 2013
################################################################################
use strict;
use warnings;

################################################################################
# Use the SCTP packages so that we can connect to the SCTP server.
################################################################################
use ExtUtils::testlib;
use Net::SCTP;

################################################################################
# These are parameters that have defaults but that can also be overridden
# by passing in things when calling the script
################################################################################
my $single_host = "127.0.0.1";
my $dest_port   = 5556;
my $message     = "I am the Client!!";
my $listen      = 1;
my $many        = 1;

################################################################################
# Variables that are declared here will be used and defined later.
################################################################################
my (@hosts, $message_length, $sctp_client);

################################################################################
# Take in parameters when the script is run and show help with an
# error if the parameter does not exist.
################################################################################
while (@ARGV)
{
  my $pass = shift @ARGV;
  if($pass eq '-l')                   { $listen    = 0; }
  elsif($pass eq '-o')                { push(@hosts, shift @ARGV); }
  elsif($pass eq '-p')                { $dest_port = shift @ARGV; }
  elsif($pass eq '-m')                { $message   = shift @ARGV; }
  elsif($pass eq '-s')                { $many      = 0; }
  elsif($pass eq '-h')                { show_help();}
  elsif($pass eq '-help')             { show_help();}
  elsif($pass eq '--help')            { show_help();}
  else                                { show_help("$pass is not a parameter");}
}

if(!@hosts || @hosts <= 1)
{
  $single_host = shift @hosts if @hosts == 1;
  ##############################################################################
  # Setup our client with the variables that have been set.
  ##############################################################################
  $sctp_client = Net::SCTP->new( {
      PeerHost  => $single_host,
      PeerPort  => $dest_port,
      Listen    => $listen,
      OneToMany => $many,
    } );
}
else
{
  $sctp_client = Net::SCTP->new( {
      PeerHost  => \@hosts,
      PeerPort  => $dest_port,
      Listen    => $listen,
      OneToMany => $many,
    } );
}

################################################################################
# Use the built in client function that calls
# socket(), setsocketopt(), and connect()
################################################################################
$sctp_client->start_client();

################################################################################
# Send a message $message using the details that we specified for our client
################################################################################
$sctp_client->sctp_sendmsg( $message );

################################################################################
# Get the message and the message length from the server
# We also pass in the buffer size of 4096 bytes. This means
# they can only give us that much.
################################################################################
($message, $message_length)  = $sctp_client->sctp_recvmsg();

################################################################################
# Print what we get
################################################################################
print "Received message: $message\n";
print "Size of: $message_length\n";

################################################################################
# Close the connection
################################################################################
$sctp_client->close();


################################################################################
# Show the help for this script if the user asks for it. If there
# is a parameter that should not have been passed in it will show it
# with an error message.
################################################################################
sub show_help
{
    if(defined(@_) or defined($_))
    {
        print "\nErrors:";
    }
    while(@_)
    {
        my $error = shift @_;
        if(@_ > 0)
        {
            print " " . $error . ",";
        }
        else
        {
            print " " . $error . "\n"
        }
    }
    print "\n\tclient -m [message]\n\n";
    print "-l\tTurn of the listener for the client.\n";
    print "-o\tOverride the default host. Default host is: $single_host\n";
    print "-p\tOverride the default port. Default port is: $dest_port\n";
    print "-m\tOverride the default message. Which is: $message\n";
    print "-s\tUse this to enable one to one connections.\n";
    exit 1;
}

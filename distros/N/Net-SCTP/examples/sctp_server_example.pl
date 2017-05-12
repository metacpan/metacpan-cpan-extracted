#!/usr/bin/perl

################################################################################
# Authors:      Brandon Casey (bcasey@cpan.org)
#               Anthony Lucillo (alucillo@cpan.org)
#
# Purpose:      An example simulation for the server of an sctp server
#               using the sctp module built using xs.
#
# Last Modified: February 28, 2013
################################################################################
use strict;
use warnings;

################################################################################
# Use the SCTP packages so that we can connect to the SCTP server.
################################################################################
use ExtUtils::testlib; # tells perl to look in blib/*
use Net::SCTP;

################################################################################
# These are parameters that have defaults but that can also be overridden
# by passing in things when calling the script
################################################################################
my $port    = 5556;
my $message = 'I am the Server!!';
my $listen  = 1;
my $many    = 1;
my $single_host = "127.0.0.1";

################################################################################
# Variables that are declared here will be used and defined later.
################################################################################
my($client_message_length, $client_message, @hosts,
      $sctp_server, $ipv6, $auto_bind);

################################################################################
# Take in parameters when the script is run and show help with an
# error if the parameter does not exist.
################################################################################
while (@ARGV)
{
  my $pass = shift @ARGV;
  if($pass eq '-l')                   { $listen    = 0; }
  elsif($pass eq '-p')                { $port      = shift @ARGV; }
  elsif($pass eq '-m')                { $message   = shift @ARGV; }
  elsif($pass eq '-a')                { $auto_bind = 1 }
  elsif($pass eq '-s')                { $many      = 0; }
  elsif($pass eq '-6')                { $ipv6      = 1; }
  elsif($pass eq '-o')                { push(@hosts, shift @ARGV); }
  elsif($pass eq '-h')                { show_help();}
  elsif($pass eq '-help')             { show_help();}
  elsif($pass eq '--help')            { show_help();}
  else                                { show_help("$pass is not a parameter");}
}


if(!@hosts || @hosts <= 1)
{
  $single_host = shift @hosts if @hosts == 1;
  @hosts = undef;
  $sctp_server = Net::SCTP->new( {
      LocalHost => $single_host,
      LocalPort => $port,
      Listen    => $listen,
      OneToMany => $many,
    } );
}
else
{
  $sctp_server = Net::SCTP->new( {
      LocalHost => \@hosts,
      LocalPort => $port,
      Listen    => $listen,
      OneToMany => $many,
    } );
}

################################################################################
# Start our server using the built in function which calls
# socket(), setsockopt(), bind(), and listen().
################################################################################
$sctp_server->start_server();

################################################################################
# Keep our server going unless we quit out of it
################################################################################
while( $sctp_server->get_Socket() )
{
  ##############################################################################
  # If we are in one to one mode then we have to use accept on
  # connections that are coming to us.
  ##############################################################################
  $sctp_server->accept() if ! $many;

  ##############################################################################
  # Get the message and the message length from the client
  # We also pass in the buffer size of 4096 bytes. This means
  # they can only give us that much.
  ##############################################################################
  ($client_message, $client_message_length) = $sctp_server->sctp_recvmsg();

  ##############################################################################
  # Use some getters and setters to get the client connections port
  # and their IP and tell the user what they are. Then we print the message
  ##############################################################################
  print "\n" . $sctp_server->get_PeerHost();
  print  ":" . $sctp_server->get_PeerPort() . "\n";
  print "Receiving Message: $client_message\n";
  print "Size of: $client_message_length\n";

  ##############################################################################
  # Send our response to the client and repeat
  ##############################################################################
  $sctp_server->sctp_sendmsg( $message );
}

################################################################################
# If there is an error we will come here and end the script
# and close the connection.
################################################################################
$sctp_server->close();

exit 1;

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
    print "\n\tserver -m [message]\n\n";
    print "-l\tTurn of the listener for the server.\n";
    print "-o\tOverride the default host. Default host is: $single_host\n";
    print "-p\tOverride the default port. Default port is: $port\n";
    print "-6\tUse this if you are passing in an ipv6\n";
    print "-m\tOverride the response message. Which is: $message\n";
    print "-s\tUse this to enable one to one connections.\n\n";
    exit 1;
}

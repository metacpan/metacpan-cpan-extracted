# Copyright (C) 2013 by Brandon Casey & Anthony Lucillo

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Net::SCTP;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration use SCTP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('Net::SCTP', $VERSION);

# Preloaded methods go here.


##-----------------------------------------------------------------------------
#/Start Subroutine  : new
#
# Purpose           : Create and instantiate all the variables our class needs
# Parameters        : Local/Peer port & host, One to many, Debug, Listen, and
#                     IPV6 bools. Destination Socket, Local Socket,
#                     and Autobind
# Returns           : The class $self variable
# Note              : undef is false and anything else is true for all bools
#                     Also if IPV6 is true our socket will be using v6 which
#                     Supports v4 and v6. If not it will only support v4 ip's

sub new
{
  my $class = shift;
  my $arg = shift;

  my $self = {
    # Our Socket descriptor
    Socket     => undef,
    # The LocalHost, usually only the server bothers with this.
    # Can be a scalar array reference if you want multiple ip's
    LocalHost  => exists $arg->{LocalHost}  ? $arg->{LocalHost} : "",
    # The LocalPort, usually only the server bothers with this.
    LocalPort  => exists $arg->{LocalPort}  ? $arg->{LocalPort} : 0,
    # The PeerHost, what you want to connect to
    # Can be a scalar array reference if you want multiple ip's
    PeerHost   => exists $arg->{PeerHost}   ? $arg->{PeerHost}  : "",
    # The PeerPort, port for what you want to connect to
    PeerPort   => exists $arg->{PeerPort}   ? $arg->{PeerPort}  : 0,
    # Should Listen be on?
    Listen     => exists $arg->{Listen}     ? $arg->{Listen}    : 1,
    # Is one to many connection?
    OneToMany  => exists $arg->{OneToMany}  ? $arg->{OneToMany} : 1,
    # Should Debug be on?
    Debug      => exists $arg->{Debug}      ? $arg->{Debug}     : undef,
    # Is IPV6 socket?
    IPV6       => exists $arg->{IPV6}       ? $arg->{IPV6}      : undef,
    # Should the server bind to whatever it can?
    AutoBind   => exists $arg->{AutoBind}   ? $arg->{AutoBind}  : undef,
    # Our Peers Socket descriptor
    DestSocket => undef,
  };

  bless($self, $class);
  return $self;
}

#\End Subroutine    : new
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : get_ip_version
#
# Purpose           : Get the version of the ip that we pass in
# Parameters        : ip_to_version_check
# Returns           : The ip version or an error.
# Note              : 1 is v6, 0 is v4, and -1 is an error

sub get_ip_version
{
  my $self = shift;
  my $ip_to_version_check = shift;
  my $version;

  # Is it ip version 6?
  if(ip_is_ipv6($ip_to_version_check))
  {
    $version = 1;
  }
  # How about version 4?
  elsif(ip_is_ipv4($ip_to_version_check))
  {
    $version = 0;
  }
  # Nope must be an error
  else
  {
    print "Error ip: $ip_to_version_check is not valid.\n";
    $version = -1;
  }

  return $version;
}

#\End Subroutine    : get_ip_version
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : socket
#
# Purpose           : Set up a socket descriptor
# Parameters        : One To Many and IPV6 class variables
# Returns           : The socket descriptor
# Note              : Sets $self->{Socket} to the socket we get

sub socket
{
  my $self = shift;
  my $socket;

  # Set the socket of this class equal to the variables that we have passed in

  $socket = _socket($self->{IPV6}, $self->{OneToMany});

  # Set the class socket
  $self->{Socket} = $socket;

  #\Debug information
  print "Debug: in socket()\n" if defined $self->{Debug};
  print "\tDebug: Setting socket using _socket\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: ipv:\t\t$self->{IPV6}\n" if defined $self->{Debug} and defined $self->{IPV6};
  print "\tDebug: Many:\t\t$self->{OneToMany}\n" if defined $self->{Debug};
  print "\tDebug: Created:\t\t$socket\n" if defined $self->{Debug};
  print "\tDebug: Returning:\t$self->{Socket}\n\n" if defined $self->{Debug};
  #/Debug information

  # Return that socket descriptor
  return $self->{Socket};
}

#\End Subroutine    : socket
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : bind
#
# Purpose           : Bind a server to a single ip
# Parameters        : Class Socket, LocalHost, and LocalPort
# Returns           : 0 on Success and -1 on Failure.
# Note              : If not called before sctp_sendmsg or listen
#                     addresses will be decided automatically.

sub bind
{
  my $self = shift;
  my $local_host = defined($_[0]) ? $_[0] : $self->{LocalHost};
  my ($status, $check);

  if(ref($local_host) eq "ARRAY")
  {
    print STDERR "Error: Tried to bind multiple ip addresses. Try calling bindx instead.\n";
    return -1;
  }

  if( defined($self->{AutoBind}) )
  {
    print "If you want to use bind set AutoBind to undef\n";
    return -1;
  }

  # Get the ip version of LocalHost, the only thing we should be binding to
  my $ip_version = $self->get_ip_version($local_host);

  # Make sure the ip version of the socket matches what we got
  if(defined($self->{IPV6}) && $ip_version != -1)
  {
    $check = "Match";
  }
  elsif(!defined($self->{IPV6}) && $ip_version == 0)
  {
    $check = "Match";
  }
  elsif($ip_version == -1)
  {
    $check = "Error: Bad IP";
    print "IP passed in for LocalHost is incorrect.\n";
  }
  else
  {
    $check = "Error: No Match";
    print "The IP you passed is v6 and the socket is set for only v4\n";
  }

  $status = _bind($self->{Socket}, $self->{LocalPort}, $local_host, $ip_version);

  #\Debug information
  print "Debug: in bind()\n" if defined $self->{Debug};
  print "\tDebug: Ip Check:\t$check\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: SD:\t\t$self->{Socket}\n" if defined $self->{Debug};
  print "\tDebug: LocalPort:\t$self->{LocalPort}\n" if defined $self->{Debug};
  print "\tDebug: LocalHost:\t$self->{LocalHost}\n" if defined $self->{Debug};
  print "\tDebug: IPv:\t\t$ip_version\n" if defined $self->{Debug};
  print "\tDebug: Status:\t\t$status\n\n" if defined $self->{Debug};
  #/Debug information

  return $status;
}

#\End Subroutine    : bind
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : connect
#
# Purpose           : Try to connect to a single host
# Parameters        : Class Socket, PeerHost, and PeerPort
# Returns           : 0 on Success and -1 on Failure.
# Note              : Connect can be called multiple times to create multiple
#                     connections on the same socket. If called before bind
#                     the server will automatically bind to what it needs if
#                     using listen.

sub connect
{
  my $self       = shift;
  my $peer_host = defined($_[0]) ? $_[0] : $self->{PeerHost};
  my $ip_version = $self->get_ip_version($peer_host);
  my ($status, $check);

  # Make sure the ip version of the socket matches what we -got
  if(defined($self->{IPV6}) && $ip_version != -1)
  {
    $check = "Match";
  }
  elsif(!defined($self->{IPV6}) && $ip_version == 0)
  {
    $check = "Match";
  }
  elsif($ip_version == -1)
  {
    $check = "Error: Bad IP";
    print "IP passed in for LocalHost is incorrect.\n";
  }
  else
  {
    $check = "Error: No Match";
    print "The IP you passed is v6 and the socket is set for only v4\n";
  }

  $status = _connect($self->{Socket}, $self->{PeerPort},
                                    $peer_host, $ip_version);

  #\Debug information
  print "Debug: in connect()\n" if defined $self->{Debug};
  print "\tDebug: Ip Check:\t$check\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: SD:\t\t$self->{Socket}\n" if defined $self->{Debug};
  print "\tDebug: PeerPort:\t$self->{PeerPort}\n" if defined $self->{Debug};
  print "\tDebug: PeerHost:\t$peer_host\n" if defined $self->{Debug};
  print "\tDebug: Ipv:\t\t$ip_version\n" if defined $self->{Debug};
  print "\tDebug: Status:\t\t$status\n\n" if defined $self->{Debug};
  #/Debug information

  return $status;
}

#\End Subroutine    : connect
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : listen
#
# Purpose           : Listen for connections
# Parameters        : Class Socket and Listen
# Returns           : 0 on Success and -1 on Failure.
# Note              : Accepts them in one to many cases, Use accept and listen
#                     in one to one situations

sub listen
{
  my $self   = shift;
  my $status = _listen($self->{Socket}, $self->{Listen});

  #\Debug information
  print "Debug: in listen()\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: SD:\t\t$self->{Socket}\n" if defined $self->{Debug};
  print "\tDebug: Listen:\t\t$self->{Listen}\n" if defined $self->{Debug};
  print "\tDebug: Status:\t\t$status\n\n" if defined $self->{Debug};
  #/Debug information

  return $status;
}

#\End Subroutine    : listen
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : accept
#
# Purpose           : Accept connections in one to one connections
# Parameters        : Class Socket
# Returns           : The DestSocket, or the socket of the person
#                     who is connecting
# Note              : For use with older technologies that do not support
#                     multi-homing. Such as UDP and TCP. Use after listen

sub accept
{
  my $self = shift;

  #\Debug information
  print "Debug: in accept()\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: SD:\t\t$self->{Socket}\n" if defined $self->{Debug};
  #/Debug information

  $self->{DestSocket} = _accept($self->{Socket});

  #\Debug information
  print "\tDebug: --Got--\n" if defined $self->{Debug};
  print "\tDebug: Dest SD:\t\t$self->{DestSocket}\n\n" if defined $self->{Debug};
  #/Debug information

  return $self->{DestSocket};
}

#\End Subroutine    : accept
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_recvmsg
#
# Purpose           : Receive a message on an open connection
# Parameters        : buffer size, flags and Class variables Sock,
#                     Peer Port, and Peer Host
# Returns           : The message that it got and its length.
# Note              : In a one to one type connection it has to use DestSocket
#                     to receive the message. Otherwise it uses socket.
#                     It also dynamically sets PeerPort and Host

sub sctp_recvmsg
{
  my $self           = shift;
  my $buffer_size    = defined($_[0]) ? $_[0] : 4096;
  my $flags          = defined($_[1]) ? $_[1] : 0;
  my $message        = "";
  my $message_length = 0;
  my $socket_desc    = 0;

  # if DestSocket is defined we use that because we are doing a one
  # to one connection. Otherwise use Socket.
  if(defined($self->{DestSocket}))
  {
    $socket_desc = $self->{DestSocket};
  }
  else
  {
    $socket_desc = $self->{Socket};
  }

  #\Debug information
  print "Debug: in sctp_recvmsg()\n" if defined $self->{Debug};
  print "\tDebug: Waiting to receive....\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: SD:\t\t$socket_desc\n" if defined $self->{Debug};
  print "\tDebug: Flags:\t\t$flags\n" if defined $self->{Debug};
  print "\tDebug: Buffer:\t\t$buffer_size\n" if defined $self->{Debug};
  #/Debug information

  # Get the message filled out and the message length is returned.
  # PeerHost and Port are also filled out.
  $message_length = _sctp_recvmsg($socket_desc, $message, $buffer_size,
                                 $self->{PeerPort}, $self->{PeerHost}, $flags);

  #\Debug information
  print "\tDebug: --Got--\n" if defined $self->{Debug};
  print "\tDebug: Port:\t\t$self->{PeerPort}\n" if defined $self->{Debug};
  print "\tDebug: PeerHost:\t$self->{PeerHost}\n" if defined $self->{Debug};
  print "\tDebug: Message:\t\t$message\n" if defined $self->{Debug};
  print "\tDebug: Length:\t\t$message_length\n\n" if defined $self->{Debug};
  #/Debug information

  return($message, $message_length);
}

#\End Subroutine    : sctp_recvmsg
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_sendmsg
#
# Purpose           : Send a message on an open connection
# Parameters        : message, flags, ppid, stream, pr_value, context
#                     and Class variables Socket or DestSocket,
#                     PeerHost, PeerPort, and get_ip_version();
#                     Peer Port, and Peer Host
# Returns           : 0 on Success and -1 on Failure.
# Note              : Some parameters NYI

sub sctp_sendmsg
{
  my $self    = shift;
  my $message = shift;
  #NYI
  my $ppid     = 0;
  my $flags    = 0;
  my $stream   = 0;
  my $pr_value = 0;
  my $context  = 0;
  #NYI

  my ($socket_desc, $ip_version, $ip, $result, $host_to_test, $i);

  # Find out what socket descriptor we should pass.
  # If one to one it will be DestSocket, Otherwise it will be Socket
  if(defined($self->{DestSocket}))
  {
    $socket_desc = $self->{DestSocket};
  }
  else
  {
    $socket_desc = $self->{Socket};
  }

  #\Debug information
  print "Debug: In sctp_sendmsg()\n" if defined $self->{Debug};
  #/Debug information

  # If we are dealing with an array of peer Hosts
  if(ref($self->{PeerHost}) eq "ARRAY")
  {
    #\Debug information
    print "\tDebug: Array of possible Peer Hosts.\n" if defined $self->{Debug};
    #/Debug information

    # For each host see if the message sends successfully.
    foreach $host_to_test (@{$self->{PeerHost}})
    {
      # Get the ip version of the current host
      $ip_version = $self->get_ip_version($host_to_test);

      # Make the call and get the result
      $result     = _sctp_sendmsg($socket_desc, $message, length($message), $self->{PeerPort},
                                  $host_to_test, $ip_version, $ppid, $flags,
                                  $stream, $pr_value, $pr_value, $context);
      #\Debug information
      print "\tDebug: --Passing--\n" if defined $self->{Debug};
      print "\tDebug: SD:\t\t$socket_desc\n" if defined $self->{Debug};
      print "\tDebug: Message:\t\t$message\n" if defined $self->{Debug};
      print "\tDebug: Port:\t\t$self->{PeerPort}\n" if defined $self->{Debug};
      print "\tDebug: IP:\t\t$host_to_test\n" if defined $self->{Debug};
      print "\tDebug: IPv:\t\t$ip_version\n" if defined $self->{Debug};
      print "\tDebug: Result:\t\t$result\n\n" if defined $self->{Debug};
      #/Debug information

      # If the send succeeded stop the loop. We do not need to send it twice
      if($result == 1)
      {
        last;
      }
    }
  }
  # We are dealing with a single PeerHost
  else
  {
    # Get the ip version of the current host
    $ip_version = $self->get_ip_version($self->{PeerHost});

    # Make the call and get the result
    $result     = _sctp_sendmsg($socket_desc, $message, length($message), $self->{PeerPort},
                                $self->{PeerHost}, $ip_version, $ppid, $flags,
                                $stream, $pr_value, $pr_value, $context);
    #\Debug information
    print "\tDebug: --Passing--\n" if defined $self->{Debug};
    print "\tDebug: SD:\t\t$socket_desc\n" if defined $self->{Debug};
    print "\tDebug: Message:\t\t$message\n" if defined $self->{Debug};
    print "\tDebug: Port:\t\t$self->{PeerPort}\n" if defined $self->{Debug};
    print "\tDebug: IP:\t\t$self->{PeerHost}\n" if defined $self->{Debug};
    print "\tDebug: IPv:\t\t$ip_version\n" if defined $self->{Debug};
    print "\tDebug: Result:\t\t$result\n\n" if defined $self->{Debug};
    #/Debug information
  }

  return $result;
}

#\End Subroutine    : sctp_sendmsg
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_bindx
#
# Purpose           : Bind a server to multiple connections
# Parameters        : Class Socket and Localhost
# Returns           : 0 on Success and -1 on Failure.
# Note              : Flag of 1 is add these addresses,
#                     flag of 2 is remove them

sub sctp_bindx
{
  my $self = shift;
  my @ip_version;
  my $i = 0;
  my $result;
  my @temp_array;
  my $local_host = defined($_[0]) ? $_[0] : $self->{LocalHost};
  my $flag = defined($_[1]) ? $_[1] : 1;


  # If they want to use bindx with a single Host we have to set LocalHost
  # to a scalar array reference.
  if(ref($local_host) ne "ARRAY")
  {
    push(@temp_array, $local_host);
    $local_host = \@temp_array;
  }


  # Build the array of IP versions to be passed in
  foreach (@{$local_host})
  {
    push(@ip_version, $self->get_ip_version($_));
  }

  $result = _sctp_bindx($self->{Socket}, $self->{LocalPort},
                       $local_host, \@ip_version, $flag);

  #\Debug information
  if(defined($self->{Debug}))
  {
    print "Debug: in sctp_bindx()\n";
    print "\tDebug: --Passing--\n";
    print "\tDebug: SD:\t\t$self->{Socket}\n";
    print "\tDebug: LocalPort:\t$self->{LocalPort}\n";

    foreach (@{$local_host})
    {
      print "\tDebug: LocalHost $i:\t$_\n";
      ++$i;
    }
    $i = 0;
    foreach (@ip_version)
    {
      print "\tDebug: IPv $i:\t\t$_\n";
      ++$i;
    }
    print "\tDebug: Flag:\t\t$flag\n";
    print "\tDebug: Result:\t\t$result\n\n";
  }
  #/Debug information
  return $result;
}

#\End Subroutine    : sctp_bindx
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_connectx
#
# Purpose           : Attempt to connect to multiple addresses
# Parameters        : Class Socket and Localhost
# Returns           : 0 on Success and -1 on Failure.
# Note              : Id - An output parameter that if passed in as a non-NULL
#                     will return the association identification for the newly
#                     created association

sub sctp_connectx
{
  my $self = shift;
  my @ip_version;
  my $id = defined($_[0]) ? $_[0] : 0; # The id to set this association to
  my $peer_host = defined($_[1]) ? $_[1] : $self->{PeerHost};
  my $i = 0;
  my $result;
  my @temp_array;

  # If they want to use connectx with a single Host we have to set PeerHost
  # to a scalar array reference.
  if(ref($peer_host) ne "ARRAY")
  {
    push(@temp_array, $peer_host);
    $peer_host = \@temp_array;
  }
  # Build the array of IP versions to be passed in
  foreach (@{$peer_host})
  {
    push(@ip_version, $self->get_ip_version($_));
  }

  $result = _sctp_connectx($self->{Socket}, $self->{PeerPort},
                           $peer_host, \@ip_version, $id);

  #\Debug information
  if(defined($self->{Debug}))
  {
    print "Debug: in sctp_connectx()\n";
    print "\tDebug: --Passing--\n";
    print "\tDebug: SD:\t\t$self->{Socket}\n";
    print "\tDebug: PeerPort:\t$self->{PeerPort}\n";

    foreach (@{$peer_host})
    {
      print "\tDebug: PeerHost $i:\t$_\n";
      ++$i;
    }
    $i = 0;
    foreach (@ip_version)
    {
      print "\tDebug: IPv $i:\t\t$_\n";
      ++$i;
    }
    print "\tDebug: id:\t\t$id\n";
    print "\tDebug: Result:\t\t$result\n\n";
  }
  #/Debug information

  return $result;
}

#\End Subroutine    : sctp_connectx
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : close
#
# Purpose           : Close the connection on the socket
# Parameters        : Class Socket
# Returns           :
# Note              :

sub close
{
  my $self = shift;

  #\Debug information
  print "Debug: in close()\n" if defined $self->{Debug};
  print "\tDebug: Closing Connection\n" if defined $self->{Debug};
  #/Debug information

  # Call close
  _close( $self->{Socket} );
}

#\End Subroutine    : close
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_peeloff
#
# Purpose           : Branch of an association into a separate socket
# Parameters        : Class Socket, and id
# Returns           : -1 on error, or the branched off socket id
#                     in $i_assoc_id
# Note              : Currently Untested

sub sctp_peeloff
{
  my $self = shift;
  my $assoc_id = defined($_[0]) ? $_[0] : $self->{Socket}; # The association id of the thing to be branched off
  my $result;

  $result =  _sctp_peeloff($self->{Socket}, $assoc_id);

  #\Debug information
  print "Debug: in sctp_peeloff()\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: Socket:\t\t$self->{Socket}\n" if defined $self->{Debug};
  print "\tDebug: id:\t\t$assoc_id\n" if defined $self->{Debug};
  print "\tDebug: Resulting id:\t$result\n\n" if defined $self->{Debug};
  #/Debug information

  return $result;
}

#\End Subroutine    : sctp_peeloff
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : shutdown
#
# Purpose           : Shutdown the connection on the socket
# Parameters        : How to and Class Socket
# Returns           : The destination socket descriptor
# Note              : Used for TCP compatibility
# $how_to           : 1 = Disables further receive operations
#                     2 = Disables further sends, and starts SCTP shutdown
#                     3 = Disables further send and receive operations
#                         and initiates the SCTP shutdown sequence.

sub shutdown
{
  my $self = shift;
  my $how_to = defined($_[0]) ? $_[0] : 1;
  if($how_to == 1)
  {
    $how_to = "SHUT_RD";
  }
  elsif($how_to == 2)
  {
    $how_to = "SHUT_WR";
  }
  elsif($how_to == 3)
  {
    $how_to = "SHUT_RDWR";
  }
  else
  {
    print "Not a valid shutdown option. Setting to default of 1\n";
    $how_to = "SHUT_RD";
  }

  #\Debug information
  print "Debug: in shutdown()\n" if defined $self->{Debug};
  print "\tDebug: --Passing--\n" if defined $self->{Debug};
  print "\tDebug: Socket:\t\t$self->{Socket}\n" if defined $self->{Debug};
  print "\tDebug: How:\t\t$how_to\n" if defined $self->{Debug};
  print "\tDebug: Socket has been shut down\n\n" if defined $self->{Debug};
  #/Debug information

  # Call the shutdown
  _shutdown($self->{DestSocket}, $how_to);
}

#\End Subroutine    : shutdown
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : getpeername
#
# Purpose           : Get the peer address on a one to one style socket
# Parameters        : Destination Socket
# Returns           : Ip address of the Destination Sockets peer
# Note              : Mostly for Compatibility with TCP does not work
#                     on one to many sockets. Called by the server

sub getpeername
{
  my $self = shift;
  my $length;
  my $peer_ip = q{};


  $length = _getpeername($self->{DestSocket}, $peer_ip);
  return ($peer_ip, $length);
}

#\End Subroutine    : getpeername
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : getsockname
#
# Purpose           : Get the peer address on a one to one style socket
# Parameters        : Destination Socket
# Returns           : Ip address of the Destination Sockets peer
# Note              : Mostly for Compatibility with TCP does not work
#                     on one to many sockets. Called by the server

sub getsockname
{
  my $self = shift;
  my $length;
  my $local_ip = q{};

  $length = _getsockname($self->{Socket}, $local_ip);
  return ($local_ip, $length);
}

#\End Subroutine    : getsockname
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_getpadders
#
# Purpose           : Get the peer addresses that you are connected to
# Parameters        : Class Socket, and association id
# Returns           : Three array values, The peer ips, the peer ports, and
#                     the peer ip versions of those ips
# Note              : Automatically calls sctp_freepaddrs

sub sctp_getpadders
{
  my $self = shift;
  my $id = defined($_[0]) ? $_[0] : 0; # the association id of the peers
  my (@peer_ips, @peer_ports, @peer_ip_versions, $length);
  my $i = 0; # Length should always start at one

  $length = _sctp_getladdrs($self->{Socket}, $id, \@peer_ips, \@peer_ports, \@peer_ip_versions);

  # We have to get ip version in the format that we use.
  while($i <= @peer_ip_versions)
  {
    $peer_ip_versions[$i] -= 1;
  }
  #\Debug information
  if(defined($self->{Debug}))
  {
    print "Debug: in sctp_getpadders()\n";
    print "\tDebug: Peer Addresses:\n";
    $i = 0;
    while($i <= ($length-1))
    {
      print "\tDebug: Address:\t\t". ($i+1) ."\n";
      print "\tDebug: IP:\t\t" . $peer_ips[$i] . "\n";
      print "\tDebug: Port:\t\t" . $peer_ports[$i] . "\n";
      print "\tDebug: IPv6:\t\t" . ($peer_ip_versions[$i]-1) . "\n";
      ++$i;
    }
  }
  #/Debug information

  return(@peer_ips, @peer_ports, @peer_ip_versions);
}

#\End Subroutine    : sctp_getpadders
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : sctp_getladders
#
# Purpose           : Get the local addresses that you are connected to
# Parameters        : Class Socket, and association id
# Returns           : Three array values, The local ips, the local ports, and
#                     the local ip versions of those ips
# Note              : Automatically calls sctp_freeladdrs

sub sctp_getladders
{
  my $self = shift;
  my $id = defined($_[0]) ? $_[0] : 0; # the association id of the localhost
  my (@local_ips, @local_ports, @local_ip_versions, $length);
  my $i = 0; # Length should always start at one

  $length = _sctp_getladdrs($self->{Socket}, $id, \@local_ips, \@local_ports, \@local_ip_versions);

  # We have to get ip version in the format that we use.
  while($i <= @local_ip_versions)
  {
    $local_ip_versions[$i] -= 1;
  }
  #\Debug information
  if(defined($self->{Debug}))
  {
    print "Debug: in sctp_getladders()\n";
    print "\tDebug: Local Addresses:\n";
    $i = 0;
    while($i <= ($length-1))
    {
      print "\tDebug: Address:\t\t". ($i+1) ."\n";
      print "\tDebug: IP:\t\t" . $local_ips[$i] . "\n";
      print "\tDebug: Port:\t\t" . $local_ports[$i] . "\n";
      print "\tDebug: IPv6:\t\t" . ($local_ip_versions[$i]-1) . "\n";
      ++$i;
    }
  }
  #/Debug information

  return(@local_ips, @local_ports, @local_ip_versions);
}
#\End Subroutine    : sctp_getladders
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : setsockopt
#
# Purpose           : To set socket options as defined in the specifications
# Parameters        : A hash of a hash containing the options to set
# Returns           : Success(0) or failure(-1)
# Note              : Supported Options, Currently does not support all
#                     SCTP_RTOINFO
#                     SCTP_ASSOCINFO
#                     SCTP_INITMSG
#                     SCTP_AUTOCLOSE
#                     SCTP_SET_PEER_PRIMARY_ADDR
#                     SCTP_PRIMARY_ADDR
#                     SCTP_ADAPTION_LAYER
#                     SCTP_DISABLE_FRAGMENTS
#                     SCTP_PEER_ADDR_PARAMS
#                     SCTP_DEFAULT_SEND_PARAM
#                     SCTP_EVENTS
#                     SCTP_I_WANT_MAPPED_V4_ADDR
#                     SCTP_MAXSEG
#                     SCTP_AUTH_CHUNK
#                     SCTP_AUTH_KEY
#                     SCTP_PEER_AUTH_CHUNKS
#                     SCTP_LOCAL_AUTH_CHUNKS
#                     SCTP_HMAC_IDENT
#                     SCTP_AUTH_SETKEY_ACTIVE
#                     SCTP_DELAYED_ACK_TIME
#                     SCTP_STATUS
#                     SCTP_GET_PEER_ADDR_INFO
#                     Currently unsupported

#sub setsockopt
#{
#  my $self = shift;
#  my $hash = shift;
#
#  print "Debug: in setsockopt()\n" if defined $self->{Debug};
#  print "\tDebug: --Passing--\n" if defined $self->{Debug};
#  foreach my $key (keys %{$hash})
#  {
#    print "\t$key => \n" if defined $self->{Debug};
#    foreach my $key2 (keys %{$hash->{$key}})
#    {
#        print "\t\t$key2 => \n" if defined $self->{Debug};
#        print "\t\t\t" . $hash->{$key}->{$key2} ."\n" if defined $self->{Debug};
#    }
#  }
#
#  _setsockopt($self->{Socket}, $hash);
#}

#\End Subroutine    : setsockopt
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : getsockopt
#
# Purpose           : to get socket options that are currently in use
# Parameters        : Socket and the empty hash to be filled out
# Returns           : Success(0) or failure(-1)
# Note              : Socket options that are supported can be seen above.
#                     Currently Not working

#sub getsockopt
#{
#  my $self = shift;
#  #my %hash_ref = defined($_[0]) ? $_[0] : 0;
#
#  #return _getsockopt($self->{Socket}, \%hash_ref);
#  #_getsockopt($self->{Socket});
#}

#\End Subroutine    : getsockopt
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : start_server
#
# Purpose           : Quickly start and test a server with the server.pl and
#                     the client.pl files
# Parameters        :
# Returns           :
# Note              :

sub start_server
{
  my $self = shift;
  print "\nDebug: calling socket()\n" if defined $self->{Debug};
  $self->socket();

  #print "Debug: calling setsockopt()\n" if defined $self->{Debug};
  #$self->setsockopt();
  if(ref($self->{LocalHost}) eq "ARRAY" and !defined($self->{AutoBind}))
  {
    print "Debug: Multihost call sctp_bindx()\n" if defined $self->{Debug};
    $self->sctp_bindx();
  }
  elsif(defined($self->{AutoBind}))
  {
    print "Debug: Automatically Binding\n" if defined $self->{Debug};
  }
  else
  {
    print "Debug: call bind()\n" if defined $self->{Debug};
    $self->bind();
  }
  print "Debug: call listen()\n" if defined $self->{Debug};
  $self->listen();
}

#\End Subroutine    : start_server
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : start_client
#
# Purpose           : Quickly start and test a server with the server.pl and
#                     the client.pl files
# Parameters        : connect type - whether to use connectx or connect
# Returns           :
# Note              :

sub start_client
{
  my $self = shift;
  print "\n\nDebug: in start_client()\n" if defined $self->{Debug};
  print "Debug: call socket()\n" if defined $self->{Debug};
  $self->socket();
  #print "Debug: in setsockopt()\n" if defined $self->{Debug};
  #$self->setsockopt();
  if(ref($self->{PeerHost}) eq "ARRAY")
  {
    print "Debug: Multihost call sctp_connectx()\n" if defined $self->{Debug};
    $self->sctp_connectx();
  }
  else
  {
    print "Debug: call connect()\n" if defined $self->{Debug};
    $self->connect();
  }
}

#\End Subroutine    : start_client
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start             : UNSUPPORTED CODE
# Purpose           : To keep code may be useful later but warn about using it

sub sctp_sendx
{
  my $self = shift;
  #my $message = shift;
  #my @ip_version;
  #$self->{PeerHost} = shift if defined($_[0]);
  #$self->{PeerPort} = shift if defined($_[0]);

  #foreach (@{$self->{PeerHost}})
  #{
  #  push(@ip_version, $self->get_ip_version($_));
  #}

  #my $socket_desc = ( defined($self->{DestSocket}) ) ? $self->{DestSocket} : $self->{Socket};
  #return _sctp_sendx( $socket_desc, $message, $self->{PeerPort}, $self->{PeerHost}, \@ip_version );
}

sub sctp_sendv
{
  my $self = shift;
  #return _sctp_sendv(i_sd, const struct iovec *iov, int iovcnt, sz_addrs, i_addrcnt, info, socklen_t infolen, i_infotype, i_flags);
}

sub sctp_recvv
{
  my $self = shift;
  #return _sctp_recvv(i_sd, const struct iovec *iov, int iovlen, sz_from, socklen_t *fromlen, info, socklen_t *infolen, unsigned int *infotype, i_flags);
}

#\End               : UNSUPPORTED CODE
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start             : Mutators
# Purpose           : Set various class variables

sub set_OneToMany
{
  my $self = shift;

  $self->{OneToMany} = shift;
}

sub set_listener
{
  my $self = shift;

  $self->{Listen} = shift;
}

sub set_DestSocket
{
  my $self = shift;

  $self->{DestSocket} = shift;
}

sub set_LocalHost
{
  my $self = shift;

  $self->{LocalHost} = shift;
}

sub set_LocalPort
{
  my $self = shift;

  $self->{LocalPort} = shift;
}

sub set_PeerPort
{
  my $self = shift;

  $self->{PeerPort} = shift;
}

sub set_PeerHost
{
  my $self = shift;

  $self->{PeerHost} = shift;
}

sub set_IPV6
{
  my $self = shift;

  $self->{IPV6} = shift;
}

sub set_Socket
{
  my $self = shift;

  $self->{Socket} = shift;
}

sub set_Debug
{
  my $self = shift;

  $self->{Debug} = shift;
}

sub set_AutoBind
{
  my $self = shift;

  $self->{AutoBind} = shift;
}

#\End               : Mutators
##----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start             : Accessors
# Purpose           : Access various class variables

sub get_OneToMany
{
  my $self = shift;

  return $self->{OneToMany};
}


sub get_listener
{
  my $self = shift;

  return $self->{Listen};
}

sub get_LocalHost
{
  my $self = shift;

  return $self->{LocalHost};
}

sub get_LocalPort
{
  my $self = shift;

  return $self->{LocalPort};
}

sub get_PeerHost
{
  my $self = shift;

  return $self->{PeerHost};
}

sub get_PeerPort
{
  my $self = shift;

  return $self->{PeerPort};
}

sub get_IPV6
{
  my $self = shift;

  return $self->{IPV6};
}

sub get_Socket
{
  my $self = shift;

  return $self->{Socket};
}

sub get_DestSocket
{
  my $self = shift;

  return $self->{DestSocket};
}

sub get_Debug
{
  my $self = shift;

  return $self->{Debug};
}

sub get_AutoBind
{
  my $self = shift;

  return $self->{AutoBind};
}

#\End               : Accessors
##----------------------------------------------------------------------------


###############################################################################
# Credit goes to NET::IP for the following: ip_is_ipv4 and ip_is_ipv6         #
# Which are located below this point!                                         #
###############################################################################

##-----------------------------------------------------------------------------
#/Start Subroutine  : ip_is_ipv4
#
# Purpose           : Check if an IP address is version 4
# Params            : IP address
# Returns           : 1 (yes) or 0 (no)

sub ip_is_ipv4
{
  my $ip = shift;
  my $ERROR;
  my $ERRNO;

  # Check for invalid chars
  unless ($ip =~ m/^[\d\.]+$/)
  {
    $ERROR = "Invalid chars in IP $ip";
    $ERRNO = 107;
    return 0;
  }

  if ($ip =~ m/^\./)
  {
    $ERROR = "Invalid IP $ip - starts with a dot";
    $ERRNO = 103;
    return 0;
  }

  if ($ip =~ m/\.$/)
  {
    $ERROR = "Invalid IP $ip - ends with a dot";
    $ERRNO = 104;
    return 0;
  }

  # Single Numbers are considered to be IPv4
  if ($ip =~ m/^(\d+)$/ and $1 < 256) { return 1 }

  # Count quads
  my $n = ($ip =~ tr/\./\./);

  # IPv4 must have from 1 to 4 quads
  unless ($n >= 0 and $n < 4)
  {
    $ERROR = "Invalid IP address $ip";
    $ERRNO = 105;
    return 0;
  }

  # Check for empty quads
  if ($ip =~ m/\.\./)
  {
    $ERROR = "Empty quad in IP address $ip";
    $ERRNO = 106;
    return 0;
  }

  foreach (split /\./, $ip)
  {

    # Check for invalid quads
    unless ($_ >= 0 and $_ < 256)
    {
      $ERROR = "Invalid quad in IP address $ip - $_";
      $ERRNO = 107;
      return 0;
    }
  }
  return 1;
}

#\End Subroutine    : ip_is_ipv4
##-----------------------------------------------------------------------------


##-----------------------------------------------------------------------------
#/Start Subroutine  : ip_is_ipv6
#
# Purpose           : Check if an IP address is version 6
# Params            : IP address
# Returns           : 1 (yes) or 0 (no)

sub ip_is_ipv6
{
  my $ip = shift;
  my $ERROR;
  my $ERRNO;

  # Count octets
  my $n = ($ip =~ tr/:/:/);
  return 0 unless ($n > 0 and $n < 8);

  # $k is a counter
  my $k;

  foreach (split /:/, $ip)
  {
    $k++;

    # Empty octet ?
    next if ($_ eq '');

    # Normal v6 octet ?
    next if (/^[a-f\d]{1,4}$/i);

    # Last octet - is it IPv4 ?
    if ( ($k == $n + 1) && ip_is_ipv4($_) )
    {
      $n++; # ipv4 is two octets
      next;
    }

    $ERROR = "Invalid IP address $ip";
    $ERRNO = 108;
    return 0;
  }

  # Does the IP address start with : ?
  if ($ip =~ m/^:[^:]/)
  {
    $ERROR = "Invalid address $ip (starts with :)";
    $ERRNO = 109;
    return 0;
  }

  # Does the IP address finish with : ?
  if ($ip =~ m/[^:]:$/)
  {
    $ERROR = "Invalid address $ip (ends with :)";
    $ERRNO = 110;
    return 0;
  }

  # Does the IP address have more than one '::' pattern ?
  if ($ip =~ s/:(?=:)/:/g > 1)
  {
    $ERROR = "Invalid address $ip (More than one :: pattern)";
    $ERRNO = 111;
    return 0;
  }

  # number of octets
  if ($n != 7 && $ip !~ /::/)
  {
    $ERROR = "Invalid number of octets $ip";
    $ERRNO = 112;
    return 0;
  }

  # valid IPv6 address
  return 1;
}

#\End Subroutine    : ip_is_ipv6
##-----------------------------------------------------------------------------

###############################################################################
# END OF CREDIT!                                                              #
###############################################################################

1;
__END__

=head1 NAME

Net::SCTP - A Stream Control Transmission Protocol(SCTP) module for Perl

=head1 USE

  use Net::SCTP;

=head1 REQUIRED INSTALL

lksctp-tools
lksctp-tools-devel

=head1 DESCRIPTION

An SCTP (Stream Control Transport Protocol) module created for Perl using XS
with the Net extension because it is a net module.

SCTP is a streaming protocol of things like UDP and TCP. It is used in new
technologies like LTE for phones. It streams data from multiple or one source
to multiple or one source. If one connection is lost the data is not lost because
it will continue to buffer until it gets the connection back and gets the rest of
the message. It is also backwards compatible with TCP.

We used the draft 11 of the SCTP architecture for this module. A link is
listed in the SEE ALSO section.

Tested on CentOS 5.2 with an i686 architecture using
lksctp-tools-1.0.6-1.el5.1.i386 with IPv4.

This module has not been tested with IPv6, although the features are available.

=head2 CURRENT STATE

=over 4

Currently setsockopt is not fully working and has not been implemented.
getsockopt is not implemented. sctp_peeloff has not been tested.
Finally we have no support for sctp_opt_info. Eventually all of these will
be supported, but for now you should be able to work without them.

Currently  send(), recv(), sendto(), recvfrom(),
read(), write(), and sctp_send() are not supported; however,
may eventually be supported.

sctp_sendmsg & sctp_recvmsg do not currently support the
use of parameters other than what you need to get them working.

=back

=head2 UNSUPPORTED

=over 4

Although there may be some code for the following functions they
have not been tested. Furthermore they were not supported in our
version of lksctp-tools so we had no way to implement them.

Functions:
sctp_send, sctp_sendx, sctp_sendv, sctp_recvv

=back

=head1 SAMPLE CODE

=head2 SERVER EXAMPLE

=over 4

A server example can be seen in the directory with the program.
One is also included here for good measure but the one in the
directory is more extensive and has comments.

  use Net::SCTP;

  my $port    = 5556;
  my $message = 'I am the Server!!';
  my $listen  = 1;
  my $many    = 1;
  my $single_host = "xxx.xxx.xx.xx";

  my($client_message_length, $client_message, @hosts,
      $sctp_server, $ipv6, $auto_bind);

  # Create the server with one host or multiple hosts.

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

  $sctp_server->socket();

  $sctp_server->bind();

  $sctp_server->listen();

  while( $sctp_server->get_Socket() )
  {
    $sctp_server->accept() if ! $many;

    ($client_message, $client_message_length) = $sctp_server->sctp_recvmsg();

    print "\n" . $sctp_server->get_PeerHost();
    print  ":" . $sctp_server->get_PeerPort() . "\n";
    print "Receiving Message: $client_message\n";
    print "Size of: $client_message_length\n";

    $sctp_server->sctp_sendmsg( $message );
  }

  $sctp_server->close();

=back

=head2 CLIENT EXAMPLE

=over 4

A client example can be seen in the directory with the program.
One is also included here for good measure but the one in the
directory is more extensive and has comments.

  use Net::SCTP;


  my $single_host = "xxx.xxx.xx.xx";
  my $dest_port = 5556;
  my $message   = "I am the Client!!";
  my $listen    = 1;
  my $many      = 1;

  my (@hosts, $message_length, $sctp_client);

  # Whether we have multiple hosts to connect to or one
  if(!@hosts || @hosts <= 1)
  {
    $single_host = shift @hosts if @hosts == 1;
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

  $sctp_client->socket();

  $sctp_client->connect();

  $sctp_client->sctp_sendmsg( $message );

  ($message, $message_length)  = $sctp_client->sctp_recvmsg();


  print "Received message: $message\n";
  print "Size of: $message_length\n";

  $sctp_client->close();

=back

=head1 CONSTRUCTOR

=over 4

=item new ( \%ARGS )

Creates a new Net::SCTP object.  Net::SCTP provides the following key-value pairs:

  LocalHost     Local host bind address
  LocalPort     Local host bind port
  PeerHost      Remote host address
  PeerPort      Remote port or service
  Listen        Set to 1 to accept new connections
  OneToMany     true for one-to-many and false one-to-one style connections
  Debug         true will print debug info
  IPV6          true for an IPv6 network, defaults to false for IPv4

=back

=head2 METHODS

=over 4

=item socket ()

Sets up a socket descriptor.

=item bind ( $peer_host )

Bind a server to a single IPv4 or IPv6 address.
The $peer_host parameter is optional if the user provides
a PeerHost in the new() function.

=item connect ( $peer_host )

Connect to a single host. Connect can be called multiple
times to create multiple connections on the same socket.
If called before bind the server will automatically bind
to what it needs if using listen.

The $peer_host parameter is optional if the user provides
a PeerHost in the new() function.

=item listen ()

By default, new associations are not accepted for one-to-many style
sockets.  An application uses listen() to mark a socket as being able
to accept new associations. For one-to-one connection types
you will need to use accept() instead.

=item accept ()

Removes an established SCTP association from the accept queue of
the endpoint.  A new socket descriptor will be returned from
accept() to represent the newly formed association.

=item ($message, $message_length) = sctp_recvmsg ( $buffer_size, $flags )

Returns SCTP messages it receives and as a second parameter returns the message length.
If the length of the message received is greater than $buffer_size, the message will
be "chunked".  This means that the received message will be broken up into several smaller
messages with the length of each message being at most the $buffer_size.

=item sctp_sendmsg ( $message )

Send a message on an open connection.

=item bindx ( \@local_addresses, $flag )

Pass an array reference to bind to multiple IPv4 or IPv6 addresses.
If you provide this array reference to the LocalHost in the new() function, this parameter is optional.

=item sctp_connectx ( \@peer_host )

Optionally pass an array reference to bind to connect to multiple IPv4 or IPv6 peer addresses.
If you provide this array reference to the PeerHost in the new() function, this parameter is optional.

=item close ()

Close the connection on a socket.

=item sctp_peeloff ()

Branch an association into a seperate socket.

=item shutdown ()

Shutdown the connection on the socket.

=item sctp_getpadders ()

Get the peer address you are connected to.

=item sctp_getladders ()

Get the local address you are connected to.

=item setsockopt ( \%hash )

Set the options for a socket.  This function takes a hash of hashes.  The keys for the
inner hash are the enumeration text for each socket option and the keys within those
inner hashes are the variables for the respective struct.  This function allows users
to set multiple socket options in a single function call.  It not necessary to provide
the variables that you do not want to set.

**Note: Not all of the socket options have been implemented at this point.
***Note: No longer supported. It was breaking things.

=over 4

Example:

  $sctp_object->setsockopt( {
    SCTP_EVENTS => {
        sctp_data_io_event => 1,
        sctp_association_event => 1,
        sctp_authentication_event => 0
      }
    },
    SCTP_RTOINFO => {
      srto_initial => 5,
    },
  );

=back

=item getsockopt ()

Returns a hash of socket options similar to format described above in setsockopt.
**Note: Not yet implemented

=item start_server ()

Performs server style start up for SCTP.  This function is simply provided for
convenience, you do not need to call this function to create an SCTP server.

=item start_client ()

Performs client style start up for SCTP.  This function is simply provided for
convenience, you do not need to call this function to create an SCTP client.

=item ($peer_ip , $peer_length) = getpeername ()

Query a socket descriptor for a peer address. This function is
invoked by the server and will return the address and the length
of the address for use.

This function will only work with one to one style sockets and is mostly for
compatibility with older socket types like TCP. Use sctp_getpadders() for
one to many type sockets.

The $peer_host parameter is optional if the user provides
a PeerHost in the new() function.

=item ($local_ip , $local_length) = getsockname ()

Query a socket descriptor for a server address. This function is
invoked by the peer and will return the address and the length
of the address for use.

This function will only work with one to one style sockets and is mostly for
compatibility with older socket types like TCP. Use sctp_getladders() for
one to many type sockets.

=back

=head1 SEE ALSO

The documentation for SCTP, that this module was built off of:
http://tools.ietf.org/html/draft-ietf-tsvwg-sctpsocket-11

=head1 AUTHORS

Anthony Lucillo
<alucillo@cpan.org>

Brandon Casey
<bcasey@cpan.org>

=head1 COPYRIGHT LICENSE

Copyright (C) 2013 by Brandon Casey & Anthony Lucillo

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

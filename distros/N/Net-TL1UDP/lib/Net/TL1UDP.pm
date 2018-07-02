package Net::TL1UDP;
    
use strict;
use warnings;
use Socket;
    
BEGIN {
   require Exporter;
   # Set the version for version checking
   our $VERSION = 1.02;
   # Inherit from Exporter to export functions and variables
   our @ISA = qw(Exporter);
   # Functions and variables which are exported by default
   our @EXPORT = qw(
      node_login
      tl1_cmd
      tl1_cmdf
      debug_file
      close_debug
      retrieve_sid
      retrieve_ctag
      command_timeout
      timeout_counter
      inhibit_messages
      sarb_retry_limit
      sarb_retry_delay
      logoff
   );
} 

my $currentCTAG  = 0;      # Initialise the current CTAG value
my $sid          = '';     # Initialise the SID value
my $timeout      = 60;     # Initialise the response timeout value
my $udpPort      = 13001;  # Initialise UDP port number
my $debug        = 0;      # Initialise the debug status
my $deviceIP     = '';     # Initialise the device IP address
my $to_counter   = 0;      # Initialise the timeout counter value
my $inhibit_msgs = 1;      # Initialise the inhibit messages status
my $loginOK      = 0;      # Initialise the logged in state
my $sarb_retries = 0;      # Initialise the SARB retry limit
my $sarb_delay   = 0;      # Initialise the SARB retry delay value

# Function to configure the debug file
sub debug_file  {
   my $filename = shift;
   open (DEBUG, ">$filename") or die "File Error: $!";
   $debug = 1;
   END { close (DEBUG) if (defined (fileno (DEBUG))); }
}

# Function to close the debug file before the script completes
sub close_debug  {
   $debug = 0;
   close (DEBUG) if (defined (fileno (DEBUG)));
}

# Function to retrieve the SID
sub retrieve_sid  { return $sid; }

# Function to return the current CTAG value
sub retrieve_ctag  { return $currentCTAG; }

# Function to retrieve or set the timeout value
sub command_timeout  {
   # If a value has been provided, set the timeout variable
   $timeout = $_[0] if (scalar(@_) == 1 && $_[0] =~ /^\d+$/ && $_[0] > 0);
   return $timeout;
}

# Function to retrieve or set the timeout counter value
sub timeout_counter  {
   # If a value has been provided, set the counter variable
   $to_counter = $_[0] if (scalar(@_) == 1 && $_[0] =~ /^\d+$/ && $_[0] >= 0);
   return $to_counter;
}

# Function to retrieve or set the SARB retry limit value
sub sarb_retry_limit  {
   # If a value has been provided, set the limit variable
   $sarb_retries = $_[0] if (scalar(@_) == 1 && $_[0] =~ /^\d+$/);
   return $sarb_retries;
}

# Function to retrieve or set the SARB retry delay value
sub sarb_retry_delay  {
   # If a value has been provided, set the retry variable
   $sarb_delay = $_[0] if (scalar(@_) == 1 && $_[0] =~ /^\d+$/);
   return $sarb_delay;
}

# Function to retrieve or set the inhibit messages value
sub inhibit_messages  {
   # If a value has been provided, set the inhibit messages value and,
   # if logged into the node, send the allow or inhibit messages command
   if (scalar(@_) == 1 && $_[0] =~ /^[01]$/)  {
      $inhibit_msgs = $_[0];
      if ($loginOK)  {
         &tl1_cmd("INH-MSG-ALL::ALL;") if ($inhibit_msgs == 1);
         &tl1_cmd("ALW-MSG-ALL::ALL;") if ($inhibit_msgs == 0);
      }
   }
   return $inhibit_msgs;
}

# Function to log into the device
sub node_login  {
   if (scalar(@_) == 3 && $_[0] =~ /^\w\S+[:]?\d*$/)  {
      my ($deviceInfo, $username, $password) = @_;
      if ($deviceInfo =~ /:/)  { ($deviceIP, $udpPort) = split (/:/, $deviceInfo); }
      else  { $deviceIP = $deviceInfo; }
      my $login = &tl1_cmd("ACT-USER::${username}:::${password};");
      if ($login && $login =~ /Logged On/i)  {
         if ($login =~ /\s+\w+\s+\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d/)  {
            ($sid) = $login =~ /\s+(\w+)\s\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d/;
            &tl1_cmd("INH-MSG-ALL::ALL;") if ($inhibit_msgs);
         }
         $loginOK = 1;
      }
      else  { &tl1_cmd("LOGOFF"); }
   }
   return $loginOK;
}

# Function to log off of the device
sub logoff  {
   &tl1_cmd("ALW-MSG-ALL::ALL;") if ($inhibit_msgs);
   &tl1_cmd("LOGOFF");
}

# Function to send a command to, and receive the data from, the socket
sub tl1_cmd  {
   if ($deviceIP)  {
      # Get the command string
      my $command_string = shift;
      # Remove the semicolon at the end of the command if it exists
      chop $command_string if (substr($command_string, -1) eq ';');
      # Assign the command to an array
      my @command = split(/:/, $command_string);
      # Ensure the array contains at least four elements
      push (@command, '') while (scalar(@command) < 4);
      # Initialise the SARB retry variable
      my $retries_remaining = $sarb_retries + 1;
      while ($retries_remaining)  {
         # Increment the CTAG value
         $currentCTAG++;
         # Replace/add the current CTAG in/to the TL-1 command
         $command[3] = $currentCTAG;
         $command_string = join(':', @command);
         # Add a semicolon to the end of the command
         $command_string .= ';';
         # Initialise data
         my $data = '';  my $msg = '';
         my $packed_ip = inet_aton($deviceIP);
         # Print the Shelf IP and the TL-1 command in the debug file
         print DEBUG "\n\n>>>>> DEVICE = $deviceIP\tCOMMAND = $command_string <<<<<\n\n" if ($debug);
         send(TL1SOCKET, $command_string, 0, sockaddr_in($udpPort, $packed_ip));
         eval  {
            # Capture alarm signal (to detect timeout)
            local $SIG{ALRM} = sub { die "timed_out\n" };
            # If the shelf does not respond in timeout secs, break out of the loop
            alarm ($timeout);
            # 5000 is the MAXIMUM data size
            while (my $src = recv(TL1SOCKET, $msg, 5000, 0))  {
               my ($srcPort, $srcAddr) = sockaddr_in($src);
               # Print ALL received data in the debug file
               print DEBUG $msg if ($debug);
               # Only add data from correct IP address and port to $data
               if ($srcAddr eq $packed_ip && $srcPort == $udpPort)  {
                  $data .= $msg;
                  # Break from the loop when a proper response and a ";"
                  # (on a line by itself) is received
                  if ($msg =~ /^;$/m)  {
                     if ($data =~ /$currentCTAG (COMPLD|DENY).+;/s)  { last; }
                     else  { $data = ""; }
                  }
                  # Reset the alarm signal
                  alarm ($timeout);
               }
               # Flag unsolicited responses in the debug file (info only)
               else  { print DEBUG "\n --- Unsolicited Response ---\n" if ($debug); }
            }
            alarm (0);
         };
         # If the timeout expired waiting for a response
         if ($@)  {
            print DEBUG "\n\n***** Timeout expired *****\n" if ($debug);
            # Increment the timeout counter
            $to_counter++;
            # Set the retries to 0
            $retries_remaining = 0;
            # Return 0
            return 0;
         }
         # Else if there was a "Status, All Resources Busy" response
         elsif ($data =~ /DENY.+SARB/s)  {
            # Decrement the remaining retries counter
            $retries_remaining--;
            # If the retry limit has not been reached, flag it in the debug file
            # and, if there is retry delay, sleep for that time period
            if ($retries_remaining)  {
               print DEBUG "\n\n***** SARB Retry - $retries_remaining remaining (waiting $sarb_delay seconds) *****\n" if ($debug);
               sleep ($sarb_delay) if ($sarb_delay);
            }
            # Otherwise return the data
            else  {
               return $data;
            }
         }
         # Otherwise, set the retries to 0 and return the data
         else  {
            $retries_remaining = 0;
            return $data;
         }
      }
   }
   else  { return 0; }
}

# Function to send a command to, and receive formatted data from, the socket
sub tl1_cmdf  {
   my $raw_data = &tl1_cmd(shift);
   if ($raw_data)  {
      if ($raw_data =~ / $currentCTAG DENY.+;/s)  {
         return $raw_data;
      }
      else  {
         my @records = $raw_data =~ /\s+["](.+?[^\\])["]/sg;
         for (my $i = 0; $i < scalar(@records); $i++)  {
            # Remove two or more spaces
            $records[$i] =~ s/\s{2,}//g;
         }
         if (scalar(@records))  { return join ("\n", @records); }
         else  { return "COMPLD"; }
      }
   }
   else  { return 0; }
}

# Create a UDP socket (TL1SOCKET) to communicate with the device
socket(TL1SOCKET, PF_INET, SOCK_DGRAM, getprotobyname("udp"))
   or die "Socket Error: $!";
   
END { close (TL1SOCKET); }

1;
__END__

=head1 NAME

Net::TL1UDP - Transaction Language 1 (TL-1) UDP Interface

=head1 SYNOPSIS

use Net::TL1UDP;

if (node_login('172.29.84.168', 'MYUSER', 'MYPASSWORD'))  {
   print tl1_cmd('RTRV-EQPT::ALL');
   print retrieve_sid;
   logoff;
}

=head1 DESCRIPTION

I<Net::TL1UDP> provides subroutines that communicate directly to a TL-1 device using UDP.  Most TL-1 modules open a telnet session to a TL-1 gateway and use it to communicate with the device.  This module communicates directly with the device.

Net::TL1UDP has been used to communicate with the Alcatel 7300, the Alcatel 7330, and the Alcatel 7342.

=over 4

=item B<node_login ('DEVICE[:PORT]', 'USERNAME', 'PASSWORD')>

Subroutine to log into the device.  The subroutine is using the following TL-1 command:  ACT-USER::(USERNAME):::(PASSWORD).  The default UDP port number is 13001 but can be changed by providing it, preceded by a colon, after the device's IP address or hostname.

If a "logged on" message is received, the subroutine returns a "1"; otherwise, it returns a "0".

=item B<tl1_cmd ('TL-1_COMMAND')>

Sends a TL-1 command to the device.  The result will be an ASCII string containing the response to the command or a "0" (if the command times out or if the login subroutine was not executed).

=item B<tl1_cmdf ('TL-1_COMMAND')>

Sends a TL-1 command to the device.  The result will be a formatted ASCII string containing the response to the command or a "0" (if the command times out or if the login subroutine was not executed).

If the command is successful (COMPLD), it strips off any response data that is NOT encapsulated in double quotation marks and removes the quotation marks as well (returning the "real" data from the response).  If the response did not contain anything encapsulated in double quotation marks, it will simply return "COMPLD".

If the command is unsuccessful (DENY), it will return the complete unformatted response.

=item B<debug_file ('path_to/debug_file')>

Creates a debug file that contains the TL-1 commands and responses.

=item B<close_debug>

Closes the debug file.  If this function is not called, the debug file will be closed (automatically) when the script finishes.

=item B<retrieve_sid>

Returns the System ID (SID) of the device if it can be determined.

=item B<retrieve_ctag>

Returns the current correlation tag (ctag) used by the module.

=item B<command_timeout ([TIMEOUT_SECS])>

Returns the current command timeout (in seconds).  Optionally, if TIMEOUT_SECS is provided, the timeout value can be changed.

The default timeout is 60 seconds.

e.g. - C<command_timeout (120)>

=item B<timeout_counter ([NUMBER])>

Returns the current number of commands that timed out (no response within the command timeout period).  Optionally, if NUMBER is provided, the counter value can be changed (e.g. - reset to 0).

e.g. - C<timeout_counter ()>

=item B<inhibit_messages ([01])>

By default, TL1UDP inhibits all autonomous messages (INH-MSG-ALL) when you log into the device.  If you want to allow autonomous messages, set inhibit_messages(0) or send the "ALW-MSG-ALL::ALL" command.  To inhibit messages again, set inhibit_messages(1) or send the "INH-MSG-ALL::ALL" command.

NOTE:  Allowing autonomous messages could affect responses to your commands.

Since TL1UDP uses a semicolon on a line by itself to determine the end of a response, a long response that is interrupted by an autonomous message (which also contains a semicolon on a line by itself) may cause the response to be terminated prematurely.

=item B<sarb_retry_limit ([NUMBER])>

Returns the current (maximum) number of command retries that will be performed due to a "Status, All Resources Busy" (SARB) response.  Optionally, if NUMBER is provided, the maximum value can be changed.

The default number of retries is 0.

e.g. - C<sarb_retry_limit ()>

=item B<sarb_retry_delay ([DELAY_SECS])>

Returns the current delay, in seconds, between command retries that will be performed due to a "Status, All Resources Busy" (SARB) response.  Optionally, if DELAY_SECS is provided, the delay can be changed.

If the "sarb_retry_limit" is 0, this parameter is ignored.

The default delay is 0 seconds.

e.g. - C<sarb_retry_limit ()>

=item B<logoff>

Sends a logoff command to the device

=back

=head1 AUTHOR

Peter Carter <pelmerc@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2013-2018 Peter Carter. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


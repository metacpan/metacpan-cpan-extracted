package POE::Component::Client::Traceroute;

use warnings;
use strict;

use vars qw($VERSION $debug $debug_socket);

$VERSION    = '0.21';

use Carp qw(croak);
use Socket;
use FileHandle;
use Time::HiRes qw(time);

use POE::Session;

BEGIN
{
   if ($^O eq "MSWin32" and $^V eq v5.8.6)
   {
      $ENV{PERL_ALLOW_NON_IFS_LSP} = 1;
   }
}

$debug         = 0;
$debug_socket  = 0;

sub DEBUG            { return $debug } # Enable debug output.
sub DEBUG_SOCKET     { return $debug_socket } # Output socket information.

use constant SO_BINDTODEVICE  => 25;   # from asm/socket.h
use constant IPPROTO_IP       => 0;    # from netinet/in.h

sub IP_TTL           { return ($^O eq "MSWin32") ? 4 : 2 } # Winsock2 vs bits.h

use constant IP_HEADERS       => 20;   # Length of IP headers
use constant ICMP_HEADERS     => 8;
use constant UDP_HEADERS      => 8;

use constant IP_PROTOCOL      => 9;

use constant UDP_DATA         => IP_HEADERS + UDP_HEADERS;
use constant ICMP_DATA        => IP_HEADERS + ICMP_HEADERS;

use constant UDP_SPORT        => IP_HEADERS + 0;
use constant UDP_DPORT        => IP_HEADERS + 2;

use constant ICMP_TYPE        => IP_HEADERS + 0;
use constant ICMP_CODE        => IP_HEADERS + 2;
use constant ICMP_ID          => IP_HEADERS + 4;
use constant ICMP_SEQ         => IP_HEADERS + 6;

use constant ICMP_PORT        => 0;

use constant ICMP_TIMEEXCEED  => 11;
use constant ICMP_ECHO        => 8;
use constant ICMP_UNREACHABLE => 3;
use constant ICMP_ECHOREPLY   => 0;

# Spawn a new PoCo::Client::Traceroute session. This is the basic
# constructor, but it does not return an object. Instead it launches
# a new POE session.

sub spawn
{
   my $type = shift;

   croak "$type->spawn() requires an even number of parameters\n" if (@_ % 2);
   my %params;

   # Force parameters to lower case to be nice to users
   for (my $i=0; $i<@_; $i+=2)
   {
      $params{lc($_[$i])} = $_[$i+1];
   }

   my $alias      = delete $params{alias} || 'tracer';
   my $firsthop   = delete $params{firsthop} || 1;
   my $maxttl     = delete $params{maxttl} || 32;
   my $timeout    = delete $params{timeout} || undef;
   my $qtimeout   = delete $params{querytimeout} || 3;
   my $queries    = delete $params{queries} || 3;
   my $baseport   = delete $params{baseport} || 33434;
   my $packetlen  = delete $params{packetlen} || 68;
   my $srcaddr    = delete $params{sourceaddress} || undef;
   my $device     = delete $params{device} || undef;
   my $perhop     = delete $params{perhoppostback} || 0;
   my $useicmp    = delete $params{useicmp} || 0;

   $debug         = delete $params{debug} || $debug;
   $debug_socket  = delete $params{debugsocket} || $debug_socket;

   if ($^O eq "MSWin32" and not $useicmp)
   {
      DEBUG and warn "TR: Windows version doesn't support UDP traceroute. " .
         "Switching to ICMP\n";
      $useicmp = 1;
   }
   
   croak(
      "$type doesn't know these parameters: ", join(', ', sort keys %params)
   ) if %params;

   croak(
      'FirstHop must be less than 255'
   ) if ($firsthop > 255);
   
   croak(
      'MaxTTL must be less than 255'
   ) if ($maxttl > 255);

   croak(
      'PacketLen can not be greater than 1492 or less than 68'
   ) if ($packetlen > 1492 or $packetlen < 68);

   POE::Session->create(
      inline_states => {
         _start            => \&tracer_start,
         _stop             => sub { },
         traceroute        => \&tracer_traceroute,
         shutdown          => \&tracer_shutdown,
         _start_traceroute => \&_start_traceroute,
         _send_packet      => \&_send_packet,
         _recv_packet      => \&_recv_packet,
         _timeout          => \&_timeout,
         _default          => \&tracer_default,
      },
      args => [
         $alias, $firsthop, $maxttl, $timeout, $qtimeout, $queries,
         $baseport, $packetlen, $srcaddr, $perhop, $useicmp, $device,
      ],
   );

   return;
}

# Startup initialization method. Sets defaults from the spawn method
# and ties the alias to the session.
sub tracer_start
{
   my (
      $kernel, $heap,
      $alias, $firsthop, $maxttl, $timeout, $qtimeout, $queries,
      $baseport, $packetlen, $srcaddr, $perhop, $useicmp, $device,
   ) = @_[ KERNEL, HEAP, ARG0..$#_ ];

   DEBUG and warn "PoCo::Client::Traceroute session $alias started\n";

   $heap->{defaults} = {
         firsthop       => $firsthop,
         maxttl         => $maxttl,
         timeout        => $timeout,
         queries        => $queries,
         querytimeout   => $qtimeout,
         baseport       => $baseport,
         packetlen      => $packetlen,
         perhoppostback => $perhop,
         useicmp        => $useicmp,
         sourceaddress  => $srcaddr,
         device         => $device,
   };

   my $proto   = getprotobyname('icmp');
   my $socket  = FileHandle->new();
   
   socket($socket, PF_INET, SOCK_RAW, $proto) || 
      croak("ICMP Socket error - $!");
   
   DEBUG_SOCKET and warn "TRS: Created ICMP socket to receive errors\n";
   $heap->{icmpsocket} = $socket;

   $kernel->select_read($socket, '_recv_packet');

   $heap->{alias}       = $alias;
   $kernel->alias_set($alias);

   return;
}

# The traceroute state takes 2 required and one optional argument. The first
# is the event to post back to the sender, the second is the host to traceroute
# to, the last is an array ref with options to override the defaults.

# The function verifies the options and returns an error if any are incorrect.
# It also starts the timer for the per traceroute timeout which is a safety
# net to keep the process from hanging if something goes wrong.
sub tracer_traceroute
{
   my ($kernel, $heap, $sender, $event, $host, $useroptions) = 
      @_[ KERNEL, HEAP, SENDER, ARG0..ARG2 ];

   unless ($event)
   {
      if (DEBUG) { die "Postback state name required for traceroute\n" }
      return;
   }
   my $error; 

   DEBUG and warn "TR: Starting traceroute to $host\n" if ($host);
   $error = "Host required for traceroute\n" unless ($host);

   my %options = %{$heap->{defaults}};
   my $callback;

# Allow user to override options for each traceroute request
   if (ref $useroptions eq 'ARRAY')
   {
      my @useropts = @$useroptions;
      $error = "traceroute useroptions requires an even number of parameters\n" 
         if (@useropts % 2);
      my %uparams;

      for (my $i=0; $i<@useropts; $i+=2)
      {
         $uparams{lc($useropts[$i])} = $useropts[$i+1];
      }

      $callback = delete $uparams{callback};

      foreach my $option (keys %options)
      {
         $options{$option} = delete $uparams{$option} 
            if (exists $uparams{$option});
      }
      
      $error .= "traceroute doesn't know these parameters: " . 
         join(', ', sort keys %uparams) . "\n" if %uparams;
   }
   elsif (defined $useroptions)
   {
      $error .= "traceroute's third argument must be an array ref\n";
   }

   $error .= "Baseport is too high, must be less than 65280\n"
      if ($options{baseport} > 65279);

   $error .= "MaxTTL can not be higher than 255\n"
      if ($options{maxttl} > 255);

   $error .= "FirstHop can not be higher than 255\n"
      if ($options{firsthop} > 255);

   $error .= "FirstHop must be less than or equal to MaxTTL\n"
      if ($options{firsthop} > $options{maxttl});

   $error .= "PacketLen can't be greater than 1492 or less than 68\n"
      if ($options{packetlen} > 1492 or $options{packetlen} < 68);

   my $postback = $sender->postback( $event, $host, \%options, $callback );

   if ($error)
   {
      DEBUG and warn "Errors starting traceroute\n";
      $postback->( _build_postback_options(undef, $error) );
   }
   else
   {
      my $trsessionid = ++$heap->{trsessionid};

      $heap->{sessions}{$trsessionid}{postback}    = $postback;
      $heap->{sessions}{$trsessionid}{options}     = \%options;
      $heap->{sessions}{$trsessionid}{host}        = $host;

      if ($options{perhoppostback})
      {
         $heap->{sessions}{$trsessionid}{callback} = $callback;
         $heap->{sessions}{$trsessionid}{sender}   = $sender;
      }

      if ($options{timeout})
      {
         my $alarm = 
            $kernel->delay_set('_timeout',$options{timeout},$trsessionid,1);

         $heap->{sessions}{$trsessionid}{timeout} = $alarm;
      }

      $kernel->yield('_start_traceroute' => $trsessionid);
   }

   return;
}

# The shutdown state takes no parameters. It closes all open sockets,
# posts back data to waiting sessions and removes any alarms.
sub tracer_shutdown
{
   my ($kernel, $heap) = @_[ KERNEL, HEAP ];
   DEBUG and warn "PoCo::Client::Traceroute session $heap->{alias} " .
      "shutting down\n";

   $kernel->select_read($heap->{icmpsocket});
   $kernel->alarm_remove_all();

   foreach my $trsessionid (keys %{$heap->{sessions}})
   {
      my $session = $heap->{sessions}{$trsessionid};

      my $error = "Traceroute session shutdown\n";

      $session->{postback}->(_build_postback_options($session,$error));
      $kernel->alarm_remove($session->{timeout});
      delete $heap->{sessions}{$trsessionid};
   }

   $kernel->alias_remove($heap->{alias});

   return 1;
}

# The following state functions are private, for internal use only.

# This function opens up the socket and verifies it. It tells the POE Kernel
# to wait for read readiness on the socket and it starts the 
# _send_packet / _recv_packet loop.

sub _start_traceroute
{
   my ($kernel,$heap,$trsessionid) = @_[ KERNEL, HEAP, ARG0 ];
   my $session = $heap->{sessions}{$trsessionid};

   return unless ($_[SESSION] eq $_[SENDER]);

   DEBUG and warn "TR: Starting traceroute session $trsessionid\n";

   my $socket  = FileHandle->new();
   if (not $session->{options}{useicmp})
   {
      my $proto = getprotobyname('udp');
   
      socket($socket, PF_INET, SOCK_DGRAM, $proto) or
         croak("UDP Socket error - $!");
   }
   elsif ($session->{options}{device} or 
            $session->{options}{sourceaddress} ne '0.0.0.0')
   {
      my $proto = getprotobyname('icmp');

      socket($socket, PF_INET, SOCK_RAW, $proto) or
         croak("ICMP Socket Error - $!");
   }
   else
   {
      undef $socket;
   }

   if ($socket)
   {
      DEBUG_SOCKET and warn "TRS: Created socket $socket\n";

      if ($session->{options}{device})
      {
         my $device = $session->{options}{device};
         setsockopt($socket, SOL_SOCKET, SO_BINDTODEVICE(), 
               pack('Z*', $device)) or croak "error binding to $device - $!";

         DEBUG_SOCKET and warn "TRS: Bound socket to $device\n";
      }

      if (  $session->{options}{sourceaddress} and 
            $session->{options}{sourceaddress} ne '0.0.0.0' )
      {
         _bind($socket, $session->{options}{sourceaddress});
      }

   }
   elsif ($session->{options}{useicmp})
   {
      $socket = $heap->{icmpsocket};
      $session->{icmpsocket} = 1;
   }
   else
   {
      $session->{postback}->(
            _build_postback_options(undef,"Could not create socket\n")
      );
   }

   my $destination = inet_aton($session->{host});
   if (not defined $destination)
   {
      $session->{postback}->(
            _build_postback_options(undef,"Could not resolve $destination\n")
      );
   }
   else
   {
      $session->{destination}    = $destination;
      $session->{socket_handle}  = $socket;
      
      $kernel->yield( '_send_packet' => $trsessionid );
   }

   return;
}

# This function connects to the remote destination on the current port
# and sets the TTL on the socket before sending a UDP packet. It also
# starts the query timeout alarm which is cleared when a packet is
# received.

sub _send_packet
{
   my ($kernel, $heap, $trsessionid) = @_[ KERNEL, HEAP, ARG0 ];
   my $session = $heap->{sessions}{$trsessionid};

   return unless ($_[SESSION] eq $_[SENDER]);
   
   if (not exists $session->{hop})
   {
      $session->{hop} = $session->{options}{firsthop};
   }

   my $hop           = $session->{hop};
   my $currentquery  = scalar keys %{$session->{hops}{$hop}};

   my $message;
   my $saddr;

   if ($session->{options}{useicmp})
   {
      my $port    = ICMP_PORT;
      $saddr      = _connect($session,$port);

      my $seq     = ++$heap->{lastseq} & 0xFFFF;
      
      my $data    = sprintf("%05i/%03i/%02i/",$trsessionid,$hop,$currentquery);
      $data      .= 'a' x ($session->{options}{packetlen} - ICMP_DATA - 13);

      my $pkt     = pack('CC n3 A' . length($data), 
                           ICMP_ECHO,  # Type
                           0,          # Code
                           0,          # Checksum (will be computed next)
                           $$,         # ID (PID)
                           $seq,       # Sequence
                           $data,      # Data
                        );

      my $chksum  = _checksum($pkt);

      $message    = pack('CC n3 A' . length($data), 
                           ICMP_ECHO,  # Type
                           0,          # Code
                           $chksum,    # Checksum
                           $$,         # ID (PID)
                           $seq,       # Sequence
                           $data,      # Data
                        );

      $heap->{sequences}{$seq}   = $trsessionid;
      $session->{lastseq}        = $seq;
   }
   else
   {
      my $port    = ($session->{lastport}) ? 
         $session->{lastport} + 1 : $session->{options}{baseport} + $hop - 1;

      $message = 'a' x ($session->{options}{packetlen} - UDP_DATA);
   
      if (not exists $session->{lastport} or $session->{lastport} != $port)
      {
         _connect($session,$port);

         $session->{lastport}                   = $port;
         $heap->{ports}{$session->{localport}}  = $trsessionid;
      }
   }

   $session->{lasttime} = time;
   my $alarm            = $kernel->delay_set('_timeout', 
         $session->{options}{querytimeout}, $trsessionid, 0);

   $session->{alarm}    = $alarm;

   DEBUG and warn "TR: Sent packet for $trsessionid\n";
   if ($session->{options}{useicmp})
   {
      send($session->{socket_handle}, $message, 0, $saddr);
   }
   else
   {
      send($session->{socket_handle}, $message, 0);
   }
   
   return;
}

# This function reads in the packet. Decodes the packet and then verifies
# the packet belongs to an active traceroute. If not the packet is discarded.
# If it does then the information from the packet and it's RTT are stored
# in the session heap and the alarm for the query timeout is cleared.
# Finally it checks if it needs to send more packets by calling 
# _process_results.

sub _recv_packet
{
   my ($kernel, $heap, $socket) = @_[ KERNEL, HEAP, ARG0 ];
   my ($recv_msg, $from_saddr, $from_port, $from_ip);
   my ($trsessionid, $replytime, $lasthop);

   return unless ($_[SESSION] eq $_[SENDER]);

   $replytime  = time;
   $lasthop    = 0;

   $from_saddr = recv($socket, $recv_msg, 1500, 0);
   if (defined $from_saddr)
   {
      ($from_port,$from_ip)   = sockaddr_in($from_saddr);
      $from_ip                = inet_ntoa($from_ip);
      DEBUG and warn "TR: Received packet from $from_ip\n";
   }
   else
   {
      DEBUG and warn "TR: No packet?\n";
      return;
   }

   my $proto         = unpack('C',substr($recv_msg,IP_PROTOCOL,1));
   
   if ($proto != 1)
   {
      my $protoname = getprotobynumber($proto);
      DEBUG and warn "TR: Packet protocol not ICMP $proto($protoname)\n";
      return;
   }

   my ($type,$code)  = unpack('CC',substr($recv_msg,ICMP_TYPE,2));
   my $icmp_data     = substr($recv_msg,ICMP_DATA);

   if (not $icmp_data)
   {
      DEBUG and warn "TR: No data in packet.\n";
      return;
   }
   
   if (  $type == ICMP_TIMEEXCEED or 
         $type == ICMP_UNREACHABLE or 
         $type == ICMP_ECHOREPLY )
   {

# This is kind of a hack. It checks if the first two bytes in little-endian
# order equal 8, which is 0800 (type 8 code 0). Otherwise the packet must be
# a udp traceroute reply. Only if the UDP source port was 8 would this fail.
# We always choose a high port for UDP, so it should never fail.
      my $rawcode = unpack('v',substr($icmp_data,ICMP_TYPE,2));
      
      if ($type != ICMP_ECHOREPLY and $rawcode != ICMP_ECHO)
      {
         my $sport      = unpack('n',substr($icmp_data,UDP_SPORT,2));
         my $dport      = unpack('n',substr($icmp_data,UDP_DPORT,2));

         $from_port     = $dport; # Set $from_port from the UDP packet
         $trsessionid   = $heap->{ports}{$sport};
         $lasthop       = ($type == ICMP_UNREACHABLE) ? 1 : 0;
      }
      else # Must not be a UDP packet, try icmp
      {
         if ($type == ICMP_ECHOREPLY)
         {
            my $icmp_id = unpack('n',substr($recv_msg,ICMP_ID,2));
            return unless ($icmp_id == $$);

            my $seq     = unpack('n',substr($recv_msg,ICMP_SEQ,2));

            my ($hop, $currentquery);

            ($trsessionid,$hop,$currentquery) = 
               map{int $_} grep{/^\d+$/} split('/',$icmp_data);

            if ($hop != $heap->{sessions}{$trsessionid}{hop})
            {
               DEBUG and warn 
                  "TR: Packet out of order or after timeout, dropping\n";
               return;
            }
            
            $from_port     = $seq; # Reusing the variable
            $lasthop       = 1; 

            DEBUG and warn "Got echo reply for $trsessionid\n";
         }
         else
         {
            my $icmp_id = unpack('n',substr($icmp_data,ICMP_ID,2));
            return unless ($icmp_id == $$);

            my $ptype   = unpack('C',substr($icmp_data,ICMP_TYPE,1));
            my $pseq    = unpack('n',substr($icmp_data,ICMP_SEQ,2));
            if ($ptype eq ICMP_ECHO)
            {
               $trsessionid   = $heap->{sequences}{$pseq};
               $from_port     = $pseq; # Reusing the variable
            }
         }
      }
   }

   if ($trsessionid and $from_ip)
   {
      my $session = $heap->{sessions}{$trsessionid};
      DEBUG and warn "TR: Received packet for $trsessionid\n";

      if (($session->{options}{useicmp} and $from_port != $session->{lastseq})
            or ( not $session->{options}{useicmp} and 
                 $from_port != $session->{lastport} ) )
      {
         DEBUG and warn "TR: Packet out of order or after timeout, dropping\n";
         return;
      }

      $kernel->alarm_remove($session->{alarm});

      my $hop           = $session->{hop};
      my $currentquery  = scalar keys %{$session->{hops}{$hop}};

      $session->{hops}{$hop}{$currentquery} = {
            remoteip    => $from_ip,
            replytime   => $replytime - $session->{lasttime},
      };

      $session->{stop} = $lasthop;

      my $continue = _process_results($session,$currentquery);

      if ($continue)
      {
         $kernel->yield('_send_packet',$trsessionid);
      }
      else
      {
         $kernel->alarm_remove($session->{timeout});
         delete $heap->{sessions}{$trsessionid};
      }
   }

   return;
}

# This function is called whenever a query times out or the whole traceroute
# times out. The $stop argument determines the state. When a query times out
# The port number is incremented so that late replies don't mess up the system.
# If a query timed out, then an * is stored for the RTT and the next packet
# is sent.

sub _timeout
{
   my ($kernel,$heap,$trsessionid,$stop) = @_[ KERNEL,HEAP,ARG0,ARG1 ];
   my $session = $heap->{sessions}{$trsessionid};

   return unless $session;
   return unless ($_[SESSION] eq $_[SENDER]);

   if ($stop)
   {
      my $error = "Traceroute session timeout\n";

      $session->{postback}->(_build_postback_options($session,$error));
      $kernel->alarm_remove($session->{timeout});

      delete $heap->{sessions}{$trsessionid};
      return;
   }

   my $hop           = $session->{hop};
   my $currentquery  = scalar keys %{$session->{hops}{$hop}};

   $session->{hops}{$hop}{$currentquery} = {
         remoteip    => '',
         replytime   => '*',
   };

   DEBUG and warn "TR: Timeout on $hop ($currentquery) for $trsessionid\n";

   my $continue = _process_results($session,$currentquery);
   if ($continue)
   {
      # Reconnect on timeout so we get a new port.
      if (not $session->{options}{useicmp})
      {
         $session->{lastport}++;

         _connect($session,$session->{lastport});
         $heap->{ports}{$session->{localport}} = $trsessionid;
      }
      $kernel->yield('_send_packet',$trsessionid);
   }
   else
   {
      $kernel->alarm_remove($session->{timeout});
      delete $heap->{sessions}{$trsessionid};
   }

   return;
}

# Just in case we were sent a bad event name.

sub tracer_default
{
   DEBUG and warn "Unknown state: " . $_[ARG0] . "\n";
   return;
}

# Internal private functions


# This function binds the socket to a local IP address. It croaks on error.

sub _bind
{
   my ($socket, $sourceaddress) = @_;

   my $ip = inet_aton($sourceaddress);
   croak("TR: nonexistant local address $sourceaddress") unless (defined $ip);

   CORE::bind($socket, sockaddr_in(0,$ip)) ||
      croak("TR: bind error - $!\n");

   DEBUG_SOCKET and warn "TRS: Bound socket to $sourceaddress\n";

   return 1;
}

# This function connects a socket to a remote system and sets the socket TTL

sub _connect
{
   my ($session,$port)  = @_;
   
   my $hop              = $session->{hop};
   my $socket_addr      = sockaddr_in($port,$session->{destination});

   if (not $session->{options}{useicmp})
   {
      connect($session->{socket_handle},$socket_addr);
      DEBUG_SOCKET and warn "TRS: Connected to $session->{host}\n";
   }

   setsockopt($session->{socket_handle}, IPPROTO_IP, IP_TTL, pack('C',$hop));
   DEBUG_SOCKET and warn "TRS: Set TTL to $hop\n";

   if (not $session->{options}{useicmp})
   {
      my $localaddr           = getsockname($session->{socket_handle});
      my ($lport,$addr)       = sockaddr_in($localaddr);
      $session->{localport}   = $lport;
   }

   return $socket_addr;
}

# This function is called after every packet is received or timed out.
# It increments the hop count, sends PerHopPostbacks and regular Postbacks
# and then returns if there are more queries to be sent or the traceroute
# is complete.

sub _process_results
{
   my ($session,$currentquery) = @_;

   if ($currentquery + 1 == $session->{options}{queries})
   {
      if ($session->{options}{perhoppostback})
      {
         my $postback = $session->{sender}->postback(
               $session->{options}{perhoppostback},
               $session->{host},
               $session->{options},
               $session->{callback}
         );

         my $hop  = $session->{hop};
         my @rows = _build_hopdata($session->{hops}{$hop}, $hop);

         $postback->( $hop, \@rows, undef ); # No error
      }

      $session->{hop}++;
      if ($session->{hop} > $session->{options}{maxttl} or $session->{stop})
      {
         my $error = ($session->{stop}) ? 
            undef : 'MaxTTL exceeded without reaching target';

         $session->{postback}->(_build_postback_options($session,$error));
         return 0;
      }
   }

   return 1;
}

# This function takes the session heap and turns it into the response
# which is sent back to the postback function.

sub _build_postback_options
{
   my ($session,$error) = @_;

   my $hops    = 0;
   my @hopdata = ();
   
   if (defined $session)
   {
      foreach my $hop (sort {$a <=> $b} keys %{$session->{hops}})
      {
         my @rows = _build_hopdata($session->{hops}{$hop},$hop);
         $hops = $hop if $rows[0]->{routerip};

         push (@hopdata,@rows);
      }
   }

   my @response = ( $hops, \@hopdata, $error );
   return @response;
}

# This function builds the actual data structure for each hop.

sub _build_hopdata
{
   my ($hopref,$hop) = @_;

   my @hopdata       = ();
   my %row           = ();
   $row{hop}         = $hop;
   
   my @results       = ();
   foreach my $query (sort {$a <=> $b} keys %{$hopref})
   {
      my $routerip   = $hopref->{$query}{remoteip};
      my $replytime  = $hopref->{$query}{replytime};

      push (@results, $replytime);
      if (  exists $row{routerip} and 
            $routerip and $row{routerip}  and
            $row{routerip} ne $routerip )
      {
         DEBUG and warn "TR: Router IP changed during hop $hop from " .
            $row{routerip} . " to $routerip\n";

         my %newrow     = %row;
         my @newresults = @results;
         $newrow{results} = \@newresults;
         push (@hopdata,\%newrow);
         undef %row;
         undef @results;
         $row{hop} = $hop;
      }

      $row{routerip} = $routerip unless $row{routerip};
   }

   if (@results)
   {
      $row{results} = \@results;
      push (@hopdata,\%row);
   }

   return @hopdata;
}

# Lifted verbatum from Net::Ping 2.31
# Description:  Do a checksum on the message.  Basically sum all of
# the short words and fold the high order bits into the low order bits.

sub _checksum
{
  my $msg = shift;

  my ($len_msg,       # Length of the message
      $num_short,     # The number of short words in the message
      $short,         # One short word
      $chk            # The checksum
      );

  $len_msg = length($msg);
  $num_short = int($len_msg / 2);
  $chk = 0;
  foreach $short (unpack("n$num_short", $msg))
  {
    $chk += $short;
  }                                           # Add the odd byte in
  $chk += (unpack("C", substr($msg, $len_msg - 1, 1)) << 8) if $len_msg % 2;
  $chk = ($chk >> 16) + ($chk & 0xffff);      # Fold high into low
  return(~(($chk >> 16) + $chk) & 0xffff);    # Again and complement
}

1;

__END__

=head1 NAME

POE::Component::Client::Traceroute - A non-blocking traceroute client

=head1 SYNOPSIS

  use POE qw(Component::Client::Traceroute);

  POE::Component::Client::Traceroute->spawn(
    Alias          => 'tracer',   # Defaults to tracer
    FirstHop       => 1,          # Defaults to 1
    MaxTTL         => 16,         # Defaults to 32 hops
    Timeout        => 0,          # Defaults to never
    QueryTimeout   => 3,          # Defaults to 3 seconds
    Queries        => 3,          # Defaults to 3 queries per hop
    BasePort       => 33434,      # Defaults to 33434
    PacketLen      => 128,        # Defaults to 68
    SourceAddress  => '0.0.0.0',  # Defaults to '0.0.0.0'
    PerHopPostback => 0,          # Defaults to no PerHopPostback
    Device         => 'eth0',     # Defaults to undef
    UseICMP        => 0,          # Defaults to 0
    Debug          => 0,          # Defaults to 0
    DebugSocket    => 0,          # Defaults to 0
  );

  sub some_event_handler 
  {
    $kernel->post(
        "tracer",           # Post request to 'tracer' component
        "traceroute",       # Ask it to traceroute to an address
        "trace_response",   # Post answers to 'trace_response'
        $destination,       # This is the host to traceroute to
        [
          Queries   => 5,         # Override the global queries parameter
          MaxTTL    => 30,        # Override the global MaxTTL parameter
          Callback  => [ $args ], # Data to send back with postback event
        ]
    );
  }

  # This is the sub which is called with the responses from the
  # Traceroute component.
  sub trace_response
  {
    my ($request,$response) = @_[ARG0, ARG1];

    my ($destination, $options, $callback) = @$request;
    my ($hops, $data, $error)              = @$response;

    if ($hops)
    {
      print "Traceroute results for $destination\n";

      foreach my $hop (@$data)
      {
        my $hopnumber = $hop->{hop};
        my $routerip  = $hop->{routerip};
        my @rtts      = @{$hop->{results}};

        print "$hopnumber\t$routerip\t";
        foreach (@rtts)
        {
          if ($_ eq "*") { print "* "; }
          else { printf "%0.3fms ", $_*1000; }
        }
        print "\n";
      }
    }

    warn "Error occurred tracing to $destination: $error\n" if ($error);
  }

  or
  
  sub another_event_handler 
  {
    $kernel->post(
        "tracer",           # Post request to 'tracer' component
        "traceroute",       # Ask it to traceroute to an address
        "trace_response",   # Post answers to 'trace_response'
        $destination,       # This is the host to traceroute to
        [
          # The trace_row event will get called after each hop
          PerHopPostback  => 'trace_row', 
        ]
    );
  }

  sub trace_row
  {
    my ($request,$response) = @_[ARG0, ARG1];

    my ($destination, $options, $callback) = @$request;
    my ($currenthop, $data, $error)        = @$response;

    # $data only contains responses for the current TTL
    # The structure is the same as for trace_response above
  }

=head1 DESCRIPTION

POE::Component::Client::Traceroute is a non-blocking Traceroute client.
It lets several other sessions traceroute through it in parallel, and it lets
them continue doing other things while they wait for responses.

=head2 Starting Traceroute Client

Traceroute client components are not proper objects. Instead of being created, 
as most objects are, they are "spawned" as separate sessions. To avoid 
confusion, and to remain similar to other POE::Component modules, they must
be spawned with the C<spawn> method, not created with a C<new> one.

  POE::Component::Client::Traceroute->spawn(
    Alias          => 'tracer',   # Defaults to tracer
    Parameter      => $value,      # Additional parameters
  );

Furthermore, there should never be more than one PoCo::Client:Traceroute session
spawned within an application at the same time. Doing so may cause unexpected
results.

PoCo::Client::Traceroute's C<spawn> method takes a few named parameters, all
parameters can be overridden for each call to the 'traceroute' event unless
otherwise stated.

=over 2

=item Alias => $session_alias

C<Alias> sets the component's alias. It is the target of post() calls.
Alias defaults to 'tracer'. Alias can not be overridden.

=item FirstHop => $firsthop

C<FirstHop> sets the starting TTL value for the traceroute. FirstHop defaults
to 1 and can not be set higher than 255 or greater than C<MaxTTL>.

=item MaxTTL => $maxttl

C<MaxTTL> sets the maximum TTL for the traceroute. Once this many hops have
been attempted, if the target has still not been reached, the traceroute
finishes and a 'MaxTTL exceeded without reaching target' error is returned
along with all of the data collected. MaxTTL defaults to 32 and can not be
set higher than 255.

=item Timeout => $timeout

C<Timeout> sets the maximum time any given traceroute will run. After this
time the traceroute will stop in the middle of where ever it is and a 
'Traceroute session timeout' error is returned along with all of the data 
collected. Timeout defaults to 0, which disables it completely.

=item QueryTimeout => $qtimeout

C<QueryTimeout> sets the maximum before an individual query times out. If
the query times out an * is set for the response time and the router IP 
address in the results data. QueryTimeout defaults to 3 seconds.

=item Queries => $queries

C<Queries> sets the number of queries for each hop to send. The response time
for each query is recorded in the results table. The higher this is, the
better the chance of getting a response from a flaky device, but the longer
a traceroute takes to run. Queries defaults to 3.

=item BasePort => $baseport

C<BasePort> sets the first port used for traceroute when not using ICMP.
The BasePort is incremented by one for each hop, by traceroute convention.
BasePort defaults to 33434 and can not be higher than 65279.

=item PacketLen => $packetlen

C<PacketLen> sets the length of the packet to this many bytes. PacketLen
defaults to 68 and can not be less than 68 or greater than 1492.

=item SourceAddress => $sourceaddress

C<SourceAddress> is the address that the socket binds to. It must be an IP
local to the system or the component will die. If set to '0.0.0.0', the 
default, it picks the first IP on the device which routes to the destination.

=item Device => $device

C<Device> is the device to bind the socket to. It defaults to the interface
which routes to the destination. The component will die if the device does
not exist or is shut down.

=item PerHopPostback => $event

C<PerHopPostback> turns on per hop postbacks within the component. The 
postback is sent to the event specified in the caller's session. By
default there is no PerHopPostback.

=item UseICMP => $useicmp

C<UseICMP> causes the traceroute to use ICMP Echo Requests instead of UDP
packets. This is advantagious in networks where ICMP Unreachables are disabled,
as ICMP Echo Responses are usually still allowed.

=item Debug => $debug

C<Debug> enables verbose debugging output. Debug defaults to 0. Debug can not
be overridden.

=item DebugSocket => $debug_sock

C<DebugSocket> enables verbose debugging on socket activity. DebugSocket
defaults to 0. DebugSocket can not be overridden.

=back

=head2 Events

The PoCo::Client::Traceroute session has two public event handlers.

=over 2

=item C<traceroute>

The traceroute event handler is how new hosts to traceroute are added to the
component. Any active POE session can post to this event. The component does
not have any internal queuing, so care should be made to not start more
events than your system can handle processing at one time.

=item C<shutdown>

The shutdown event closes all running traceroutes, posts back current data
with the 'Session shutdown' error message and closes the session.

=back

=head3 traceroute event

Sessions communicate asynchronously with the Client::Traceroute component.
They post traceroute requests to it, and the receive events back upon 
completion. They optionally receive events after each hop.

Requests are posted to the components 'traceroute' handler. They include
the name of an event to post back, an address to traceroute to, optionally,
parameters to override from the default, and callback arguments. The address
may be a numeric dotted quad, a packed inet_aton address, or a host name.

  $kernel->post(
    "tracer",           # Post request to 'tracer' component
    "traceroute",       # Ask it to traceroute to an address
    "trace_response",   # Post answers to 'trace_response'
    $destination,       # The system to traceroute to
    [
      Parameter => $value,    # Overrides global setting for this request
      Callback  => [ $args ], # Data to send back with postback event
    ]
  );

Traceroute responses come with two array references:

  my ($request, $response) = @_[ ARG0, ARG1 ];

C<$request> contains information about the request:

  my ($destination, $options, $callback) = @$request;

=over 2

=item C<$destination>

This is the original request traceroute destination. It matches the address
posted to the 'traceroute' event.

=item C<$options>

This is a hash reference with all the options used in the traceroute, both
the defaults and the overrides sent with the request.

=item C<$callback>

This is the callback arguments passed with the original request.

=back

C<$response> contains information about the traceroute response. It is 
different depending on if the the event was a postback or a PerHopPostback.

Postback array:

  my ($hops, $data, $error) = @$response;

PerHopPostback array:

  my ($currenthop, $data, $error) = @$response;

=over 2

=item C<$hops>

This is the largest hop with a response. It may be less than MaxTTL.

=item C<$currenthop>

This is the current hop that the data is posted for. It changes with each
call to the PerHopPostback event.

=item C<$data>

This is an array of hash references. For the Postback event, it contains at
least one row for each TTL between FirstHop and the device or MaxTTL. For
PerHopPostback events it contains at least one row for the current TTL hop.

A single TTL hop may have more than one row if the IP address changed during
polling.

The structure of the array ref is the following:

  $data->{routerip} = $routerip;
  $data->{hop}      = $currenthop;
  $data->{results}  = \@trip_times;

=over 2

=item C<$data-E<gt>{routerip}>

This is the router IP which responded with the TTL expired in transit or
destination unreachable message. If it changes, a new row is generated. If
all queries for this hop timed out than this will be set to an empty string.

=item C<$data-E<gt>{hop}>

This is the current hop that the result set is for. It is incremented by one
for each TTL between FirstHop and reaching the device or MaxTTL.

=item C<$data-E<gt>{results}>

This is an array ref containing the result round trip times for each query
in seconds, with millisecond precision depending on the system. If a query 
packet times out the entry in the array will be set to "*".

=back

=back

=head3 shutdown event

The PoCo::Client::Traceroute session must be shutdown in order to exit.
To shut down the session, post a 'shutdown' event to it. This will cause all
running traceroutes to postback their current results and the stop the session.

  $kernel->post( 'tracer' => 'shutdown' );

or

  my $success = $kernel->call( 'tracer' => 'shutdown' );

=head2 Traceroute Notes

=over 2

=item *

Only one instance of this component should be spawned at a time. Multiple
instances may have indeterminant behavior.

=item *

The component does not have any internal queue. Care should be taken to only
launch as many traceroutes as your system can handle at one time.

=back

=head1 SEE ALSO

This component's Traceroute code was heavily influenced by 
Net::Traceroute::PurePerl and Net::Ping.

See POE for documentation on how POE works.

You can learn more about POE at <http://poe.perl.org/>.

See also the test program, t/01_trace.t or the example in the 
examples directory of the distribution

=head1 DEPENDENCIES

POE::Component::Client::Traceroute requires the following modules:

L<POE>
L<Carp>
L<Socket>
L<FileHandle>
L<Time::HiRes>

=head1 BUGS AND LIMITATIONS

Please report any bugs to the author and use http://rt.cpan.org/

This module requires root or administrative privileges to run. It opens a raw 
socket to listen for TTL exceeded messages. Take appropriate precautions.

This module does not support IPv6.

This module only supports ICMP traceroutes under Windows.

This module is a little slow since it only sends one packet at a time to
any given destination.

=head1 TODO

=over 2

=item *

Implement IPv6 capability.

=item *

Implement TCP traceroute.

=item *

Send multiple requests to the same destination in parallel for each 
traceroute like the Linux traceroute application does. Currently requests to
different destinations are sent in parallel, but each packet to the same
destination is sent serially.

=back

=head1 AUTHOR

Andrew Hoying <ahoying@cpan.org>

=head1 LICENSE AND COPYRIGHT

POE::Component::Client::Traceroute is Copyright 2006 by Andrew Hoying.
All rights reserved. POE::Component::Client::Traceroute is free software; you
may redistribute it and or modify it under the same terms as Perl itself.

=cut


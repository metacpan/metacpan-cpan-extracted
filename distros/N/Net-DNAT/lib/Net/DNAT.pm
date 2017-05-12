package Net::DNAT;

use strict;
use Exporter;
use vars qw(@ISA $VERSION $listen_port);
use Net::Server::Multiplex 0.85;
use Net::Ping 2.29;
use IO::Socket;
use Carp ();

$VERSION = '0.13';
@ISA = qw(Net::Server::Multiplex);

$listen_port = getservbyname("http", "tcp");

# DEBUG warnings
$SIG{__WARN__} = sub {
  &Carp::cluck((scalar localtime).": [pid $$] WARNING\n : $_[0]");
};

# DEBUG dies
my $dying = 0;
$SIG{__DIE__} = sub {
  $dying++;
  if ($dying > 2) {
    # Safety to avoid recursive or infinite dies
    return exit(1);
  }
  print STDERR ((scalar localtime),": [pid $$] CRASHED\n : ",@_,"\n");
  if ($^S) {
    # Die within eval does not count.
    $dying--;
    # Just use regular die.
    return CORE::die(@_);
  }
  # Stack trace of who crashed.
  &Carp::confess(@_);
};


sub _resolve_it {
  my $string = shift;
  my @result = ();
  my $port = $listen_port;
  if ($string =~ s/:(\d+)//) {
    $port = $1;
  } elsif ($string =~ s/:(\w+)//) {
    $port = getservbyname($1, "tcp");
  }
  if ($string !~ /^\d+\.\d+\.\d+\.\d+$/) {
    my $j;
    ($j, $j, $j, $j, @result) = gethostbyname($string);
    die "Failed to resolve [$string] to an IP address\n"
      unless @result;
    map { $_ = join(".", unpack("C4", $_)); } @result;
  } else {
    @result = ($string);
  }
  map { $_ .= ":$port"; } @result;
  return @result;
}

sub post_configure_hook {
  my $self = shift;
  my $conf_hash = {
    @{ $self->{server}->{configure_args} }
  };
  my $old_pools_ref = $conf_hash->{pools} ||
    die "The 'pools' setting is missing!\n";
  unless (ref $old_pools_ref &&
          ref $old_pools_ref eq "HASH") {
    $old_pools_ref = { default => $old_pools_ref };
  }

  my $new_pools_ref = {};
  foreach my $poolname (keys %{ $old_pools_ref }) {
    # The first element is the cycle index
    my @list = (0);
    my $dest = $old_pools_ref->{$poolname};
    if (!ref $dest) {
      push(@list, _resolve_it($dest));
    } elsif (ref $dest eq "ARRAY") {
      foreach my $i (@{ $dest }) {
        push(@list, _resolve_it($i));
      }
    } else {
      die "Unimplemented type of pool destination [".(ref $dest)."]\n";
    }
    $new_pools_ref->{$poolname} = [ @list ];
  }
  $self->{orig_pools} = $self->{pools} = $new_pools_ref;

  my $old_switch_table_ref = $conf_hash->{host_switch_table} || {};
  my $new_switch_table_ref = {};
  foreach my $old_host (keys %{ $old_switch_table_ref }) {
    my $new_host = $old_host;
    if ($new_host =~ s/^([a-z0-9\-\.]*[a-z])\.?$/\L$1/i) {
      $new_switch_table_ref->{$new_host} = $old_switch_table_ref->{$old_host};
    } else {
      die "Invalid hostname [$old_host] in host_switch_table\n";
    }
  }
  $self->{host_switch_table} = $new_switch_table_ref;

  $self->{switch_filters} = $conf_hash->{switch_filters} || [];
  # Run a quick sanity check on each pool destination
  for (my $i = scalar $#{ $self->{switch_filters} };
       $i > 0; $i-=2) {
    if (!$self->{pools}->{$self->{switch_filters}->[$i]}) {
      die "No such 'switch_filters' pool [".($self->{switch_filters}->[$i])."]\n";
    }
  }

  $self->{default_pool} = $conf_hash->{default_pool} || undef;
  if (!defined $self->{default_pool}) {
    if (( scalar keys %{ $self->{pools} } ) == 1) {
      # Only one pool?  Guess that should be the default.
      ($self->{default_pool}) = keys %{ $self->{pools} };
    } else {
      die "The 'default_pool' setting must be specified with multiple pools!\n";
    }
  }
  if (!$self->{pools}->{$self->{default_pool}}) {
    die "The 'default_pool' [$self->{default_pool}] has not been defined!\n";
  }

  # Plenty of time to establish the tcp three-way handshake
  # for a connection to a destination node in a pool.
  $self->{connect_timeout} =
    defined $conf_hash->{connect_timeout} ?
      $conf_hash->{connect_timeout} : 3;

  if (exists $conf_hash->{check_for_dequeue}) {
    if (defined $conf_hash->{check_for_dequeue} &&
        $conf_hash->{check_for_dequeue} > 0) {
      $self->{server}->{check_for_dequeue} =
        $conf_hash->{check_for_dequeue};
    }
  } else {
    $self->{server}->{check_for_dequeue} = 60;
  }

  $self->check_pools if $self->{server}->{check_for_dequeue};
}

sub run_dequeue {
  my $self = shift;
  $self->check_pools;
}

sub check_pools {
  my $self = shift;
  my $new_pools = {};
  my $ping_cache = {};
  my $pinger = new Net::Ping "tcp", $self->{connect_timeout};
  $pinger->tcp_service_check(1);
  foreach my $pool (keys %{ $self->{orig_pools} }) {
    my $index = $self->{pools}->{$pool} ? $self->{pools}->{$pool}->[0] : 0;
    for(my $i = 1; $i < @{ $self->{orig_pools}->{$pool} }; $i++) {
      $self->log(4, "Checking pool [$pool] index [$i]...");
      my ($host, $port) = $self->{orig_pools}->{$pool}->[$i] =~ /^(.+):(\d+)$/;
      next unless($host && $port);

      my $alive;
      if(exists $ping_cache->{"$host:$port"}) {
        $alive = $ping_cache->{"$host:$port"};
        $self->log(4, "Cached  pool [$pool] index [$i] at [$host:$port] is [$alive]");
      } else {
        $self->log(4, "Testing pool [$pool] index [$i] at [$host:$port]...");
        $pinger->{port_num} = $port;
        $alive = $ping_cache->{"$host:$port"} = $pinger->ping($host);
        if (!$alive) {
          $self->log(1, "WARNING: [$host:$port] is down!");
        }
      }
      next unless($alive);
      if (!$new_pools->{$pool}) {
        $new_pools->{$pool} = [$index];
      }
      push @{$new_pools->{$pool}}, $self->{orig_pools}->{$pool}->[$i];
    }
  }
  $pinger->close;
  $self->{pools} = $new_pools;
}

sub mux_connection {
  my $self = shift;
  shift; # I do not need mux
  my $fh   = shift;
  $self->{net_server}->log(4, "Connection on fileno [".fileno($fh)."]");
  $self->{state} = "REQUEST";
  # Store tied file handle within object
  $self->{fh} = $fh;
  # Grab peer information before it's gone
  $self->{peeraddr} = $self->{net_server}->{server}->{peeraddr};
  $self->{peerport} = $self->{net_server}->{server}->{peerport};
}


sub mux_input {
  my $self = shift;
  my $mux  = shift;
  my $fh   = shift;
  my $data = shift;

  my $pool = undef; # Which pool to redirect to

  unless (defined $fh and defined fileno($fh)) {
    $self->{net_server}->log(4, "mux_input: WEIRD fh! Trashing (".length($$data)." bytes) input.  (This should never happen.)");
    $$data = "";
    return;
  }

  if ($self->{state} eq "REQUEST") {
    $self->{net_server}->log(4, "input on [REQUEST] ($$data)");
    # Ignore leading whitespace and blank lines
    while ($$data =~ s/^\s+//) {}
    if ($$data =~ s%^([^\r\n]*)\r?\n%%) {
      # First newline reached.
      my $request = $1;
      if ($request =~ m%
          (\w+)\s+        # method
          (/.*)\s+        # path
          HTTP/(1\.[01])  # protocol
          $%ix) {
        $self->{request_method}  = $1;  # GET or POST
        $self->{request_path}    = $2;  # URL path
        $self->{request_proto}   = $3;  # 1.0 or 1.1
        $self->{state} = "HEADERS";
      } else {
        $self->{state} = "CONTENT";
        $_ = $request;
        goto POOL_DETERMINED;
      }
    }
  }

  if ($self->{state} eq "HEADERS" && $$data) {
    $self->{net_server}->log(4, "input on [HEADERS] ($$data)");
    # Search for the "nothing" line
    if ($$data =~ s/^((.*\n)*)\r?\n//) {
      # Found! Jump to next state.
      $self->{request_headers_block} = $1;
      # Wipe some headers for cleaner protocol
      # conversion and for security reasons.
      $self->{request_headers_block} =~
        s%^(Connection|
            Keep-Alive|
            Remote-Addr|
            Remote-Port|
            ):.*\n
              %%gmix;

      # Add headers for Apache::DNAT
      $self->{request_headers_block} .=
        "Remote-Addr: $self->{peeraddr}\n".
          "Remote-Port: $self->{peerport}\n";

      $self->{state} = "CONTENT";
      # Determine correct pool destination
      # based on the request $_
      $_ = "$self->{request_method} $self->{request_path} HTTP/1.0\r\n$self->{request_headers_block}";
      # Rectify host header for simplicity
      s/^Host:\s*([\w\-\.]*\w)\.?((:\d+)?)\r?\n/Host: \L$1$2\r\n/im;

      # First run through the switch_filters
      my @switch_filters = @{ $self->{net_server}->{switch_filters} };
      while (@switch_filters) {
        my ($ref, $then_pool) = splice(@switch_filters, 0, 2);
        if (my $how = ref $ref) {
          if ($how eq "CODE") {
            if (&$ref()) {
              $pool = $then_pool;
              last;
            }
          } elsif ($how eq "Regexp") {
            if ($_ =~ $ref) {
              $pool = $then_pool;
              last;
            }
          } else {
            die "Switch filter to [$then_pool] smells too weird!\n";
          }
        } else {
          die "Switch filter [$ref] is not a ref!\n";
        }
      }

      # Then run through the host_switch_table
      if (!defined($pool) && m%^Host: ([\w\-\.]+)%m) {
        my $request_host = $1;

        foreach my $host (keys %{ $self->{net_server}->{host_switch_table} }) {
          if ( $request_host eq $host ) {
            $pool = $self->{net_server}->{host_switch_table}->{$host};
            last;
          }
        }
      }

    POOL_DETERMINED:
      # Otherwise, just use the default
      if (!defined($pool)) {
        $pool = $self->{net_server}->{default_pool};
      }

      $self->{net_server}->log(4, "POOL DETERMINED: [$pool]");
      my $pool_ref = $self->{net_server}->{pools}->{$pool};
      if (!$pool_ref) {
        $self->{net_server}->log(4, "Pool [$pool] is down.");
        $mux->write($fh, "ERROR: Pool [$pool] is down.\n");
        $$data = "";
        $mux->shutdown($fh, 2);
        return;
      }

      # Increment cycle counter.
      # If it exceeds pool size
      if (++($pool_ref->[0]) > $#{ $pool_ref }) {
        # Start over with 1 again.
        $pool_ref->[0] = 1;
      }
      $self->{net_server}->log(4, "POOL CYCLE INDEX [$pool_ref->[0]]");
      my $peeraddr = $pool_ref->[$pool_ref->[0]];
      $self->{net_server}->log(4, "Connecting to destination [$peeraddr]");

      $@ = "";
      my $peersock = eval {
        local $SIG{__DIE__} = 'DEFAULT';
        local $SIG{ALRM} = sub { die "Timed out!\n"; };
        alarm ($self->{net_server}->{connect_timeout});
        new IO::Socket::INET $peeraddr or die "$!\n";
      };
      alarm(0); # Reset alarm
      $peersock = undef if $@;
      if ($peersock) {
        $self->{net_server}->log(4, "Connected successfully with fileno [".fileno($peersock)."]");
        $mux->add($peersock);
        my $proxy_object = bless {
          state => "CONTENT",
          fh => $peersock,
          proto => $self->{request_proto},
          complement_object => $self,
          net_server => $self->{net_server},
        }, (ref $self);
        $self->{net_server}->log(4, "Complement for socket on fileno [".fileno($fh)."] created on fileno [".fileno($peersock)."]");
        $self->{complement_object} = $proxy_object;
        $mux->set_callback_object($proxy_object, $peersock);
        $mux->write($peersock, "$_\r\n");
        #$_ = "$self->{request_method} $self->{request_path} HTTP/1.0\r\n$self->{request_headers_block}";
      } else {
        $self->{net_server}->log(4, "Could not connect to [$peeraddr]: $@");
        $mux->write($fh, "ERROR: Pool [$pool] Index [$pool_ref->[0]] (Peer $peeraddr) is down: $!\n");
        $$data = "";
        $mux->shutdown($fh, 2);
        $self->{net_server}->check_pools if $self->{net_server}->{server}->{check_for_dequeue};
      }
    }
  }

  if ($self->{state} eq "CONTENT" && $$data) {
    # Test to make sure complement is up
    if ($self->{complement_object} and $self->{complement_object}->{fh} and
        defined fileno($self->{complement_object}->{fh})) {
      $self->{net_server}->log(4, "input on [CONTENT] on fileno [".fileno($fh)."] (".length($$data)." bytes) to socket on fileno [".fileno($self->{complement_object}->{fh})."]");
      $mux->write($self->{complement_object}->{fh}, $$data);
    } else {
      $self->{net_server}->log(4, "mux_input: Complement CONTENT socket is gone! Trashing (".length($$data)." bytes) input.");
      # close() is a bit stronger than shutdown()
      $mux->kill_output($fh);
      $mux->close($fh);
    }
    # Consumed everything
    $$data = "";
  }

}

sub mux_eof {
  my $self = shift;
  my $mux  = shift;
  my $fh   = shift;
  my $data = shift;
  $self->{net_server}->log(4, "EOF received on fileno [".fileno($fh)."] ($$data)");

  # If it hasn't been consumed by now,
  # then too bad, wipe it anyways.
  $$data = "";
  if ($self->{complement_object}) {
    $self->{net_server}->log(4, "Shutting down complement on fileno [".fileno($self->{complement_object}->{fh})."]");
    # If this end was closed, then tell the
    # complement socket to close.
    $mux->shutdown($self->{complement_object}->{fh}, 2);
    # Make sure that when the complement
    # socket finishes via mux_eof, that
    # it doesn't waste its time trying
    # to shutdown my socket, because I'm
    # already finished.
    delete $self->{complement_object}->{complement_object};
  }
}


1;
__END__

=head1 NAME

Net::DNAT - Psuedo Layer7 Packet Processer

=head1 SYNOPSIS

  use Net::DNAT;

  run Net::DNAT <settings...>;

=head1 DESCRIPTION

This module is intended to be used for testing
applications designed for load balancing systems.
It listens on specified ports and forwards the
incoming connections to the appropriate remote
applications.  The remote application can be
on a separate machine or on the same machine
listening on a different port and/or address.

=head1 SETTINGS

=head2 port

Specify which port or ports to listen on.
See L<Net::Server> for more details on the
port setting and other Net::Server settings
which may also be used with Net::DNAT.

 Example: port => 80

=head2 user

User to switch to once the server starts.
(Just used by Net::Server)

 Example: user => "nobody"

=head2 group

Group to switch to once the server starts.
(Just used by Net::Server)

 Example: group => "nobody"

=head2 pools

Supply a hash ref of pool definitions.  The
key in the hash is the pool name.  Its value
is either one destination scalar or an array
ref of one or more destinations.  If you just
specify the destination value instead of a
hash ref, it will assume it is for the "default"
pool and will also be used as "default_pool".
Each destination may be an IP address, a single
host, or a hostname of a round robin dns to
several IP addresses.  Each destination may
be followed by an optional :port to specify
which port to connect to.  The default is
http (port 80) if none is specified.

 Example: pools => {
    www => "web.server.com",
    dev => "dev.server.com",
  }

 Example: pools => "web.server.com"

=head2 default_pool

Specify which key in the pools hash ref should
be used if no specific pool could be determined
based on the request information.  If only one
pool is specified in the pools hash, that pool
is assumed to be the default_pool.

 Example: default_pool => www

=head2 host_switch_table

Specify which hosts go to which pools.

 Example: host_switch_table => {
    "server.com" => "www",
    "test.com" => "dev",
  }

=head2 switch_filters

Supply special header modifications or
provide ability to compute destination
pool based on arbitrary code.  It takes
an array ref of destination pairs.  The
first in the pair is either a regex or
a code ref.  The second of the pair is
the destination pool name from the pools
setting.  If a regex is used, the pool
is determined if the regex passes when
filtered through the header request
block.  If a code ref is used, $_ will
contain the request header block.  If
executing the code ref returns a true
value, its corresponding pool with be
used.  This is meant to be thought of
as a hash ref, but the order must be
preserved, and refs do not work very
well as hash keys, so it uses an array
ref instead.  Be aware that any
modifications to $_ will also be passed
on to the destination regardless of
whether the code ref returned a true
value or not.  Also, the switch_filters
are run before to the host_switch_table.

 Example: switch_filters => [
    qr%^Cookie:.*magic%im => "dev",
    sub { s/^(Host: )www\.%$1%im; 0; } => "dev",
  ]

=head2 connect_timeout

Specify the maximum number of seconds that a
destination node can take before it will be
considered down.  The default is 3 seconds.

 Example: connect_timeout => 10

=head2 check_for_dequeue

Net::DNAT can periodically perform service
checks on the destination node of each pool.
This setting specifies this interval in seconds.
To disable these checks, set this to 0.
The default is 60 seconds.

 Example: check_for_dequeue => 30

=head1 PEER SOCKET SPOOF

This implementation does not actually translate
the destination address in the packet headers
and resend the packet, like true DNAT does.
It is implemented like a port forwarding proxy.
When a client connects, a new socket is made to
the remote application and the connection is
tunnelled to/from the client.  This causes the
peer side of the socket to appear to the remote
application like it is coming from the Net::DNAT
box instead of the real client.  This peer
modification side effect is usually fine for
testing and developmental purposes, though.

=head1 HTTP

If you do not care about where the hits on your
web server are coming from, then you do not need
to worry about this section.  If the remote
application is the Apache 1.3.x web server,
( see http://httpd.apache.org/ ), then the
Apache::DNAT module can be used to correctly
and seemlessly UnDNATify this peer munging
described above.  If mod_perl is enabled for
Apache, then add this line to its httpd.conf:

  PerlModule Apache::DNAT
  PerlInitHandler Apache::DNAT

If you cannot do this, (because it is a web server
other than Apache, or you do not have mod_perl
enabled, or you do not have access to the web
server, or you just do not want the CPU overhead
to fix the peer back to normal, or for whatever
reason), then it will still function fine.  Just
the server logs will be inaccurate and the CGI
programs will run with the wrong environment
variables pertaining to the peer (i.e.,
REMOTE_ADDR and REMOTE_PORT).

=head1 INSTALL

See INSTALL document.

=head1 EXAMPLES

See demo/* from the distribution for some working examples.

=head1 TODO

  Test suite example using server and client though Net::DNAT.
  Test suite example using client and pool of servers.
  Test suite example using Apache::DNAT.
  Support for HTTP/1.1 protocol conversion to 1.0 protocol and back again.
  Support for HTTP/1.1 KeepAlive timeout and KeepAliveRequests.
  Support for SSL conversion to plain text and back (IO::Multiplex).
  Support for html error pages for internal errors like Server outages.
  Support for error logs.
  Support for access logs.
  Support for CVS protocol.
  Support for FTP protocol.
  Support for OOB channel data correctly.
  Support for DNS protocol.

=head1 LAYER

  More information on network layers:

  http://uwsg.iu.edu/usail/network/nfs/network_layers.html

=head1 COPYRIGHT

  Copyright (C) 2002-2003,
  Rob Brown, bbb@cpan.org

  This package may be distributed under the same terms as Perl itself.

  All rights reserved.

=head1 SEE ALSO

 L<Apache::DNAT>,
 L<Net::Server>,
 L<IO::Multiplex>

=cut

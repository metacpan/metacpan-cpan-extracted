# Author: Chris "BinGOs" Williams
# Derived from code by Dennis Taylor
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::IRC::Service::Hybrid;

use strict;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW
            Filter::Line Filter::Stream );
use POE::Filter::IRC::Hybrid;
use POE::Filter::CTCP::Hybrid;
use Carp;
use Socket;
use Sys::Hostname;
use vars qw($VERSION);

$VERSION = '0.998';

use constant PCI_REFCOUNT_TAG => "P::C::I registered";

my %irc_commands =
   ('quit'      => \&oneoptarg_client,
    'nick'      => \&onlyonearg_client,
    'invite'    => \&onlytwoargs_client,
    'kill'      => \&onlytwoargs,
    'gline'     => \&spacesep,
    'kline'     => \&spacesep,
    'jupe'      => \&spacesep,
    'privmsg'   => \&privandnotice,
    'notice'    => \&privandnotice,
    'join'      => \&sjoin,
    'stats'     => \&spacesep_client,
    'links'     => \&spacesep_client,
    'mode'      => \&spacesep_client,
    'part'      => \&commasep_client,
    'ctcp'      => \&ctcp,
    'ctcpreply' => \&ctcp,
  );

# Create a new IRC Service

sub new {
  my ($package,$alias,$hash) = splice @_, 0, 3;
  my ($package_events);

  unless ($alias and $hash) {
        croak "Not enough parameters to POE::Component::IRC::Service::Hybrid->new()";
  }

  unless (ref $hash eq 'HASH') {
        croak "Second argument to POE::Component::IRC::Service::P10::new() must be a hash reference";
  }
  
  warn "This module has now been deprecated by POE::Component::Server::IRC\n";

  $hash->{EventMode} = 1 unless ( defined ( $hash->{EventMode} ) and $hash->{EventMode} == 0 );

  $hash->{Reconnect} = 0 unless ( defined ( $hash->{Reconnect} ) and $hash->{Reconnect} == 1 );

  $hash->{Debug} = 0 unless ( defined ( $hash->{Debug} ) and $hash->{Debug} == 1 );


  if ( $hash->{EventMode} == 1 ) {
    $package_events = [qw( _start
                           _stop
                           _parseline
		           _sock_up
		           _sock_down
		           _sock_failed
			   autoping
                           addnick
                           connect
                           topic
		           irc_hyb_stats
			   irc_hyb_version
		           irc_hyb_server_link
			   irc_hyb_server
			   irc_hyb_squit
		           irc_hyb_eob
                           irc_hyb_ping
		           irc_hyb_quit
		           irc_hyb_kill
			   irc_hyb_nick
			   irc_hyb_whois
			   irc_hyb_sjoin
			   irc_hyb_part
			   irc_hyb_kick
			   irc_hyb_mode
                           kick
			   join
		           register
		           sl_server
		           sl_client
                           shutdown
		           squit
		           unregister)];
  } else {
    $package_events = [qw( _start
                           _stop
                           _parseline
		           _sock_up
		           _sock_down
		           _sock_failed
			   autoping
                           addnick
                           connect
                           topic
		           irc_hyb_stats
			   irc_hyb_version
		           irc_hyb_server_link
			   irc_hyb_server
			   irc_hyb_squit
		           irc_hyb_eob
                           irc_hyb_ping
		           irc_hyb_quit
		           irc_hyb_kill
			   irc_hyb_nick
			   irc_hyb_whois
			   irc_hyb_mode
                           kick
			   join
		           register
		           sl_server
		           sl_client
                           shutdown
		           squit
		           unregister)];
  }

  # Create our object 
  my ($self) = { };
  bless ($self);

  # Parse the passed hash reference
  unless ($hash->{'ServerName'} and $hash->{'RemoteServer'} and $hash->{'Password'} and $hash->{'ServerPort'}) {
	croak "You must specify ServerName, RemoteServer, Password and ServerPort in your hash reference.";
  }

  $hash->{ServerDesc} = "*** POE::Component::IRC::Service ***" unless defined ($hash->{ServerDesc});
  $hash->{Version} = "POE-Component-IRC-Service-P10-$VERSION" unless defined ($hash->{Version});
  $hash->{'PingFreq'} = 90 unless ( defined ( $hash->{'PingFreq'} ) );

  my @event_map = map {($_, $irc_commands{$_})} keys %irc_commands;

  POE::Session->create( inline_states => { @event_map },
			package_states => [
                        $package => $package_events, ],
                     	args => [ $alias, @_ ],
			heap => { State => $self, 
				  servername => $hash->{'ServerName'},
				  serverdesc => $hash->{'ServerDesc'},
				  remoteserver => $hash->{'RemoteServer'},
				  serverport => $hash->{'ServerPort'},
				  password => $hash->{'Password'},
				  localaddr => $hash->{'LocalAddr'},
				  pingfreq => $hash->{'PingFreq'},
				  eventmode => $hash->{'EventMode'},
				  reconnect => $hash->{'Reconnect'},
				  debug => $hash->{'Debug'},
				  version => $hash->{'Version'}, },
		      );
  return $self;
}

# Register and unregister to receive events

sub register {
  my ($kernel, $heap, $session, $sender, @events) =
    @_[KERNEL, HEAP, SESSION, SENDER, ARG0 .. $#_];

  die "Not enough arguments" unless @events;

  # FIXME: What "special" event names go here? (ie, "errors")
  # basic, dcc (implies ctcp), ctcp, oper ...what other categories?
  foreach (@events) {
    $_ = "irc_hyb_" . $_ unless /^_/;
    $heap->{events}->{$_}->{$sender} = $sender;
    $heap->{sessions}->{$sender}->{'ref'} = $sender;
    unless ($heap->{sessions}->{$sender}->{refcnt}++ or $session == $sender) {
      $kernel->refcount_increment($sender->ID(), PCI_REFCOUNT_TAG);
    }
  }
}

sub unregister {
  my ($kernel, $heap, $session, $sender, @events) =
    @_[KERNEL,  HEAP, SESSION,  SENDER,  ARG0 .. $#_];

  die "Not enough arguments" unless @events;

  foreach (@events) {
    delete $heap->{events}->{$_}->{$sender};
    if (--$heap->{sessions}->{$sender}->{refcnt} <= 0) {
      delete $heap->{sessions}->{$sender};
      unless ($session == $sender) {
        $kernel->refcount_decrement($sender->ID(), PCI_REFCOUNT_TAG);
      }
    }
  }
}

# Session starts or stops

sub _start {
  my ($kernel, $session, $heap, $alias) = @_[KERNEL, SESSION, HEAP, ARG0];
  my @options = @_[ARG1 .. $#_];

  $session->option( @options ) if @options;
  $kernel->alias_set($alias);
  $kernel->yield( 'register', qw(stats version server_link server squit eob quit kill nick whois sjoin part kick mode) );
  $heap->{irc_filter} = POE::Filter::IRC::Hybrid->new();
  $heap->{ctcp_filter} = POE::Filter::CTCP::Hybrid->new();
  $heap->{irc_filter}->debug(1) if ( $heap->{debug} );
  $heap->{connected} = 0;
  $heap->{serverlink} = "";
  $heap->{starttime} = time();
}

sub _stop {
  my ($kernel, $heap, $quitmsg) = @_[KERNEL, HEAP, ARG0];

  if ($heap->{connected}) {
    $kernel->call( $_[SESSION], 'shutdown', $quitmsg );
  }
}

# Connect to IRC Network

sub connect {
  my ($kernel, $heap, $session, $args) = @_[KERNEL, HEAP, SESSION, ARG0];

    if ($heap->{'sock'}) {
        $kernel->call ($session, 'squit');
    }

    $heap->{socketfactory} = POE::Wheel::SocketFactory->new(
                                        SocketDomain => AF_INET,
                                        SocketType => SOCK_STREAM,
                                        SocketProtocol => 'tcp',
                                        RemoteAddress => $heap->{'remoteserver'},
                                        RemotePort => $heap->{'serverport'},
                                        SuccessEvent => '_sock_up',
                                        FailureEvent => '_sock_failed',
                                        ( $heap->{localaddr} ? (BindAddress => $heap->{localaddr}) : () ),
    );
}

sub autoping {
  my ($kernel,$heap) = @_[KERNEL,HEAP];

  if ( $heap->{'socket'} ) {
    $kernel->yield( 'sl_client', "PING :$heap->{serverlink}" );
    $kernel->delay( 'autoping' => $heap->{pingfreq} );
  }
}

sub squit {
  my ($kernel, $heap) = @_[KERNEL,HEAP];

  # Don't give a f**k about any parameters passed

  if ( $heap->{'socket'} ) {
    delete ( $heap->{'socket'} );
    $kernel->yield( 'sl_client', "SQUIT $heap->{serverlink} :$heap->{servername}" );
  }
}

# Internal function called when a socket is closed.
sub _sock_down {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # Destroy the RW wheel for the socket.
  delete $heap->{'socket'};
  $heap->{connected} = 0;

  # post a 'irc_disconnected' to each session that cares
  foreach (keys %{$heap->{sessions}}) {
    $kernel->post( $heap->{sessions}->{$_}->{'ref'},
                   'irc_hyb_disconnected', $heap->{server} );
  }
}

sub _sock_up {
  my ($kernel,$heap,$session,$socket) = @_[KERNEL,HEAP,SESSION,ARG0];
  $heap->{connecttime} = time();
  $heap->{State}->_burst_create();

  delete $heap->{socketfactory};

  $heap->{localaddr} = (unpack_sockaddr_in( getsockname $socket))[1];

  $heap->{'socket'} = new POE::Wheel::ReadWrite
  (
        Handle => $socket,
        Driver => POE::Driver::SysRW->new(),
        Filter => POE::Filter::Line->new(),
        InputEvent => '_parseline',
        ErrorEvent => '_sock_down',
   );

  if ($heap->{'socket'}) {
        $heap->{connected} = 1;
  } else {
        _send_event ( $kernel, $heap, 'irc_hyb_socketerr', "Couldn't create ReadWrite wheel for IRC socket" );
  }

  foreach (keys %{$heap->{sessions}}) {
        $kernel->post( $heap->{sessions}->{$_}->{'ref'}, 'irc_hyb_connected', $heap->{remoteserver} );
  }

  $heap->{socket}->put("PASS $heap->{password} :TS\n");
  $heap->{socket}->put("CAPAB :EOB\n");
  $heap->{socket}->put("SERVER $heap->{servername} 1 :$heap->{serverdesc}\n");
  $heap->{socket}->put("SVINFO 3 3 1 :$heap->{connecttime}\n");
}

sub _sock_failed {
  my ($kernel, $heap, $op, $errno, $errstr) = @_[KERNEL, HEAP, ARG0..ARG2];

  _send_event( $kernel, $heap, 'irc_hyb_socketerr', "$op error $errno: $errstr" );
}

# Parse each line from received at the socket

# Parse a message from the IRC server and generate the appropriate
# event(s) for listening sessions.
sub _parseline {
  my ($kernel, $session, $heap, $line) = @_[KERNEL, SESSION, HEAP, ARG0];
  my (@events, @cooked);

  # Feed the proper Filter object the raw IRC text and get the
  # "cooked" events back for sending, then deliver each event. We
  # handle CTCPs separately from normal IRC messages here, to avoid
  # silly module dependencies later.

  @cooked = ($line =~ tr/\001// ? @{$heap->{ctcp_filter}->get( [$line] )}
             : @{$heap->{irc_filter}->get( [$line] )} );

  foreach my $ev (@cooked) {
    $ev->{name} = 'irc_hyb_' . $ev->{name};
    _send_event( $kernel, $heap, $ev->{name}, @{$ev->{args}} );
  }
}


# Sends an event to all interested sessions. This is a separate sub
# because I do it so much, but it's not an actual POE event because it
# doesn't need to be one and I don't need the overhead.
sub _send_event  {
  my ($kernel, $heap, $event, @args) = @_;
  my %sessions;

  foreach (values %{$heap->{events}->{'irc_hyb_all'}},
           values %{$heap->{events}->{$event}}) {
    $sessions{$_} = $_;
  }
  foreach (values %sessions) {
    $kernel->post( $_, $event, @args );
  }
}

sub addnick {
  my ($kernel, $heap, $session, $args) = @_[KERNEL, HEAP, SESSION, ARG0];
  my $connecttime = time();

  if ($args) {
    my %arg;
    if (ref $args eq 'ARRAY') {
      %arg = @$args;
    } elsif (ref $args eq 'HASH') {
      %arg = %$args;
    } else {
      die "First argument to addnick() should be a hash or array reference";
    }

    # Gentlemen, lets get down to business
    # Mandatory fields we must must must have these, damnit
    my $nickname = $arg{'NickName'} if exists $arg{'NickName'};
    my $username = $arg{'UserName'} if exists $arg{'UserName'};
    my $hostname = $arg{'HostName'} if exists $arg{'HostName'};
    my $umode = $arg{'Umode'} if exists $arg{'Umode'};
    my $description = $arg{'Description'} if exists $arg{'Description'};

    unless (defined $nickname) {
	die "You must specify at least a NickName to addnick";
    }

    # Default everything else

    my $cmd = "NICK $nickname 1 $connecttime ";
    $umode = "+o" unless (defined $umode);
    $umode = "+" . $umode unless ($umode =~ /^\+/ or not defined($umode));
    $cmd .= "$umode " if defined($umode);
    $cmd .= "+ " if not defined($umode);
    $cmd .= lc $nickname . " " unless (defined $username);
    $cmd .= "$username " if (defined $username);
    $cmd .= "$heap->{servername} " unless (defined $hostname);
    $cmd .= "$hostname " if (defined $hostname);
    $cmd .= "$heap->{servername} ";
    $cmd .= ":$heap->{serverdesc}" unless (defined $description);
    $cmd .= ":$description" if defined($description);

    $kernel->yield ( 'sl_client', $cmd ); # Kludge tbh :)

  } else {
      die "First argument to addnick() should be a hash or array reference";
  }

}

# Generate an automatic pong in response to IRC Server's ping

sub irc_hyb_ping {
  my ($heap, $arg) = @_[HEAP, ARG0];

  $heap->{socket}->put("PONG :$heap->{servername}\n");
}

sub irc_hyb_server_link {
  my ($kernel,$heap,$server) = @_[KERNEL,HEAP,ARG0];

  $heap->{Bursting} = 1;
  $heap->{State}->{serverlink} = $server;
  $heap->{serverlink} = $server;
  $heap->{State}->_server_add($server,1,$heap->{servername});
}

sub irc_hyb_eob {
  my ($kernel,$heap,$who) = @_[KERNEL,HEAP,ARG0];

  SWITCH: {
    if ( $who eq $heap->{serverlink} ) {
	foreach ( $heap->{State}->_burst_info() ) {
	   $kernel->yield( 'sl_server', $_ );
	}
	$kernel->yield( 'sl_server', "EOB" );
	$heap->{State}->_burst_destroy();
	last SWITCH;
    }
    if ( $who eq $heap->{servername} ) {
	$heap->{Bursting} = 0;
	last SWITCH;
    }
  }
}

sub irc_hyb_server {
  my ($kernel,$heap,$link,$server,$hops) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2];

  $heap->{State}->_server_add($server,$hops,$link);
}

sub irc_hyb_squit {
  my ($heap,$squit) = @_[HEAP,ARG0];

  $heap->{State}->_server_del($squit);
}

sub irc_hyb_version {
  my ($kernel, $heap, $who) = @_[KERNEL,HEAP,ARG0];

  $kernel->yield( 'sl_server', "351 $who $heap->{version}. $heap->{servername} :" );
}

sub irc_hyb_sjoin {
  my ($kernel,$heap,$who,$what) = @_[KERNEL,HEAP,ARG0,ARG1];

  $heap->{State}->_channel_burst( $what );
}

sub irc_p10_quit {
  my ($heap, $who) = @_[HEAP,ARG0];

  $heap->{State}->_nick_del($who);
}


# Our event handlers for events sent to us

# The handler for commands which have N arguments, separated by commas.
sub commasep {
  my ($kernel, $state) = @_[KERNEL, STATE];
  my $args = join ',', @_[ARG0 .. $#_];

  $state = uc( $state );
  $state .= " $args" if defined $args;
  $kernel->yield( 'sl_server', $state );
}

# The handler for commands which have N arguments, separated by commas. Client hacked.
sub commasep_client {
  my ($kernel, $state, $numeric) = @_[KERNEL, STATE, ARG0];
  my $args = join ',', @_[ARG1 .. $#_];

  $state = uc( $state );
  $state .= " $args" if defined $args;
  $kernel->yield( 'sl_client', ":$numeric $state" );
}

# Send a CTCP query or reply, with the same syntax as a PRIVMSG event.
sub ctcp {
  my ($kernel, $state, $heap, $numeric, $to) = @_[KERNEL, STATE, HEAP, ARG0, ARG1];
  my $message = join ' ', @_[ARG2 .. $#_];

  unless (defined $numeric and defined $to and defined $message) {
    die "The POE::Component::IRC event \"$state\" requires three arguments";
  }

  # CTCP-quote the message text.
  ($message) = @{$heap->{ctcp_filter}->put([ $message ])};

  # Should we send this as a CTCP request or reply?
  $state = $state eq 'ctcpreply' ? 'notice' : 'privmsg';

  $kernel->yield( $state, $numeric, $to, $message );
}

# Tell the IRC server to forcibly remove a user from a channel.
sub kick {
  my ($kernel, $numeric, $chan, $nick) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $message = join '', @_[ARG3 .. $#_];

  unless (defined $numeric and defined $chan and defined $nick) {
    die "The POE::Component::IRC event \"kick\" requires at least three arguments";
  }

  $nick .= " :$message" if defined $message;
  $kernel->yield('sl_client', ":$numeric KICK $chan $nick" );
}


# The handler for all IRC commands that take no arguments.
sub noargs {
  my ($kernel, $state, $arg) = @_[KERNEL, STATE, ARG0];

  if (defined $arg) {
    die "The POE::Component::IRC event \"$state\" takes no arguments";
  }
  $kernel->yield( 'sl_server', uc( $state ) );
}

# The handler for all IRC commands that take no arguments. Client hacked.
sub noargs_client {
  my ($kernel, $state, $numeric, $arg) = @_[KERNEL, STATE, ARG0, ARG1];

  unless (defined $numeric) {
    die "The POE::Component::IRC event \"$state\" requires at least one argument";
  }

  if (defined $arg) {
    die "The POE::Component::IRC event \"$state\" takes no arguments";
  }
  $kernel->yield( 'sl_client', ":$numeric " . uc( $state ) );
}

# The handler for commands that take one required and two optional arguments.
sub oneandtwoopt {
  my ($kernel, $state) = @_[KERNEL, STATE];
  my $arg = join '', @_[ARG0 .. $#_];

  $state = uc( $state );
  if (defined $arg) {
    $arg = ':' . $arg if $arg =~ /\s/;
    $state .= " $arg";
  }
  $kernel->yield( 'sl_server', $state );
}

# The handler for commands that take one required and two optional arguments. Client hacked.
sub oneandtwoopt_client {
  my ($kernel, $state, $numeric) = @_[KERNEL, STATE, ARG0];
  my $arg = join '', @_[ARG1 .. $#_];

  unless (defined $numeric) {
    die "The POE::Component::IRC event \"$state\" requires at least one argument";
  }

  $state = uc( $state );
  if (defined $arg) {
    $arg = ':' . $arg if $arg =~ /\s/;
    $state .= " $arg";
  }
  $kernel->yield( 'sl_client', ":$numeric $state" );
}

# The handler for commands that take at least one optional argument.
sub oneoptarg {
  my ($kernel, $state) = @_[KERNEL, STATE];
  my $arg = join '', @_[ARG0 .. $#_] if defined $_[ARG0];

  $state = uc( $state );
  if (defined $arg) {
    $arg = ':' . $arg if $arg =~ /\s/;
    $state .= " $arg";
  }
  $kernel->yield( 'sl_server', $state );
}

# The handler for commands that take at least one optional argument. Client hacked.
sub oneoptarg_client {
  my ($kernel, $state, $numeric) = @_[KERNEL, STATE, ARG0];
  my $arg = join '', @_[ARG1 .. $#_] if defined $_[ARG1];

  unless (defined $numeric) {
    die "The POE::Component::IRC event \"$state\" requires at least one argument";
  }

  $state = uc( $state );
  if (defined $arg) {
    $arg = ':' . $arg if $arg =~ /\s/;
    $state .= " $arg";
  }
  $kernel->yield( 'sl_client', ":$numeric $state" );
}

# The handler for commands which take one required and one optional argument.
sub oneortwo {
  my ($kernel, $state, $one) = @_[KERNEL, STATE, ARG0];
  my $two = join '', @_[ARG1 .. $#_];

  unless (defined $one) {
    die "The POE::Component::IRC event \"$state\" requires at least one argument";
  }

  $state = uc( $state ) . " $one";
  $state .= " $two" if defined $two;
  $kernel->yield( 'sl_server', $state );
}

# The handler for commands which take one required and one optional argument. Client hacked.
sub oneortwo_client {
  my ($kernel, $state, $numeric, $one) = @_[KERNEL, STATE, ARG0, ARG1];
  my $two = join '', @_[ARG2 .. $#_];

  unless (defined $numeric and defined $one) {
    die "The POE::Component::IRC event \"$state\" requires at least two argument";
  }
  $state = uc( $state ) . " $one";
  $state .= " $two" if defined $two;
  $kernel->yield( 'sl_client', ":$numeric $state" );
}

# Handler for commands that take exactly one argument.
sub onlyonearg {
  my ($kernel, $state) = @_[KERNEL, STATE];
  my $arg = join '', @_[ARG0 .. $#_];

  unless (defined $arg) {
    die "The POE::Component::IRC event \"$state\" requires one argument";
  }

  $state = uc( $state );
  $arg = ':' . $arg if $arg =~ /\s/;
  $state .= " $arg";
  $kernel->yield( 'sl_server', $state );
}

# Handler for commands that take exactly one argument. Client hacked.
sub onlyonearg_client {
  my ($kernel, $state, $numeric) = @_[KERNEL, STATE, ARG0];
  my $arg = join '', @_[ARG1 .. $#_];

  unless (defined $numeric and defined $arg) {
    die "The POE::Component::IRC::Service::P10 event \"$state\" requires two argument";
  }

  $state = uc( $state );
  $arg = ':' . $arg if $arg =~ /\s/;
  $state .= " $arg";
  $kernel->yield( 'sl_client', ":$numeric $state" );
}

# Handler for commands that take exactly two arguments.
sub onlytwoargs {
  my ($heap, $kernel, $state, $one) = @_[HEAP, KERNEL, STATE, ARG0];
  my ($two) = join '', @_[ARG1 .. $#_];

  unless (defined $one and defined $two) {
    die "The POE::Component::IRC::Service::P10 event \"$state\" requires two arguments";
  }

  $state = uc( $state );
  $two = ':' . $two if $two =~ /\s/;
  $kernel->yield( 'sl_server', "$state $two" );
}

# Handler for commands that take exactly two arguments. Client hacked.
sub onlytwoargs_client {
  my ($heap, $kernel, $state, $numeric, $one) = @_[HEAP, KERNEL, STATE, ARG0, ARG1];
  my ($two) = join '', @_[ARG2 .. $#_];

  unless (defined $numeric and defined $one and defined $two) {
    die "The POE::Component::IRC::Service::P10 event \"$state\" requires three arguments";
  }

  $state = uc( $state );
  $two = ':' . $two if $two =~ /\s/;
  $kernel->yield( 'sl_client', ":$numeric $state $two" );
}

# Handler for privmsg or notice events.
sub privandnotice {
  my ($kernel, $state, $numeric, $to) = @_[KERNEL, STATE, ARG0, ARG1];
  my $message = join ' ', @_[ARG2 .. $#_];

  unless (defined $numeric and defined $to and defined $message) {
    die "The POE::Component::IRC event \"$state\" requires three arguments";
  }

  if (ref $to eq 'ARRAY') {
    $to = join ',', @$to;
  }

  $state = uc( $state );
  $state .= " $to :$message";
  $kernel->yield( 'sl_client', ":$numeric $state" );
}

# Tell the IRC session to go away.
sub shutdown {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  foreach ($kernel->alias_list( $_[SESSION] )) {
    $kernel->alias_remove( $_ );
  }

  foreach (qw(socket sock socketfactory dcc wheelmap)) {
    delete $heap->{$_};
  }
}

# The handler for commands which have N arguments, separated by spaces.
sub spacesep {
  my ($kernel, $state) = @_[KERNEL, STATE];
  my $args = join ' ', @_[ARG0 .. $#_];

  $state = uc( $state );
  $state .= " $args" if defined $args;
  $kernel->yield( 'sl_server', $state );
}

# The handler for commands which have N arguments, separated by spaces. Client hacked.
sub spacesep_client {
  my ($kernel, $state, $numeric) = @_[KERNEL, STATE, ARG0];
  my $args = join ' ', @_[ARG1 .. $#_];

  $state = uc( $state );
  $state .= " $args" if defined $args;
  $kernel->yield( 'sl_server', "$numeric $state" );
}

# Dish out server initiated commands

sub sl_server {
  my ($kernel, $heap, $cmd) = @_[KERNEL, HEAP, ARG0];

  $heap->{socket}->put(":$heap->{servername} $cmd\n");
  $kernel->yield('_parseline',":$heap->{servername} $cmd");
}

# Dish out client (whichever is specified) initiated commands

sub sl_client {
  my ($kernel, $heap, $cmd) = @_[KERNEL, HEAP, ARG0];

  $heap->{socket}->put("$cmd\n");
  $kernel->yield('_parseline',$cmd);
}

# Set or query the current topic on a channel.
sub topic {
  my ($kernel,$heap, $numeric, $chan) = @_[KERNEL,HEAP, ARG0, ARG1];
  my $topic = join '', @_[ARG2 .. $#_];

  $chan .= " :$topic" if length $topic;
  $kernel->yield('sl_client',":$numeric TOPIC $chan");
}

sub sjoin {
  my ($kernel,$state,$heap,$nick,$channel) = @_[KERNEL,STATE,HEAP,ARG0,ARG1];
  my ($ts) = time();

  unless ( defined($nick) and defined($channel) ) {
    die "The POE::Component::IRC event \"$state\" requires at least two argument";
  }
  # Under TSora joins are actually implemented as server initiated events *sigh*
  $kernel->yield('sl_server',"SJOIN $ts $channel + :$nick");
}


# Our own little function to return a proper uppercase nickname or channel name IRC stylee
# See the RFC for the details

sub u_irc {
  my ($value) = shift || return undef;

  $value =~ tr/a-z{}|/A-Z[]\\/;
  return $value;
}


# Return a correctly formatted string for STATS u requests

sub timestring {
      my ($timeval) = shift || return 0;
      my $uptime = time() - $timeval;
  
      my $days = int $uptime / 86400;
      my $remain = $uptime % 86400;
      my $hours = int $remain / 3600;
      $remain %= 3600;
      my $mins = int $remain / 60;
      $remain %= 60;
      return sprintf("Server Up %d days, %2.2d:%2.2d:%2.2d",$days,$hours,$mins,$remain);
}

sub retOpflags {
  my ($opflags) = shift || return undef;
  my (@opflags) = ();
  my ($action) = "";

  for (my $i = 0; $i < length($opflags); $i++) {
    my $char = substr($opflags,$i,1);
    if ($char eq "+" or $char eq "-") {
       $action = $char;
    } else {
       push (@opflags,"$action$char");
    }
  }
  return @opflags;
}

# Object Methods
# Private methods begin with _

sub _server_add {
  my ($self) = shift;
    
  my ($server) = { Name    => $_[0],
		   Hops    => $_[1],
		   Link    => $_[2] 
		 };

  $self->{servers_name}->{ $server->{Name} } = $server;
  return 1;
}

sub _server_del {
  my ($self) = shift;
  my ($server) = shift || return 0;

  $self->{servers_name}->{$server}->{ToDelete} = 1;
  foreach ( keys %{ $self->{servers_name} } ) {
    if ( $server eq $self->{servers_name}->{$_}->{Link} and not defined ( $self->{servers_name}->{$server}->{ToDelete} ) ) {
       $self->_server_del($self->{servers_name}->{$_}->{Link});
    }
  }
  foreach ( keys %{ $self->{byserver}->{$server} } ) {
    $self->_nick_del($_);
  }
  delete ( $self->{servers_name}->{$server} );
  return 1;
}

sub _nick_add {
  my ($self) = shift;
  my ($nickname) = $_[0] || return 0;
  my ($server) = $_[1] || return 0;
  my ($username) = $_[2] || return 0;
  my ($hostname) = $_[3] || return 0;
  my ($timestamp) = $_[4] || time();
  my ($umode) = $_[5] || undef;
  my ($ircname) = $_[6] || undef;

  # Does the nickname already exist in our state, ie. one of our clients
  # If so kludge the timestamp on ours so it is older and they will get KILLed mwuahahahaha :o)
  if ( defined ( $self->{bynickname}->{ u_irc ($nickname) } ) ) {
    my ($kludge) = $timestamp - 30;
    $self->{bynickname}->{ u_irc ( $nickname ) }->{TimeStamp} = $kludge;
    if ( defined ( $self->{burst_nicks}->{ u_irc( $nickname ) } ) ) {
      $self->{burst_nicks}->{ u_irc( $nickname ) }->{TimeStamp} = $kludge;
    }
  }

  if ( not defined ( $self->{bynickname}->{ u_irc( $nickname ) } ) ) {
    my ($record) = { NickName => $nickname,
		     UserName => $username,
		     HostName => $hostname,
		     IRCName => $ircname,
		     TimeStamp => $timestamp,
		     Server => $server,
		     UMode => $umode, };
    $self->{bynickname}->{ u_irc ( $record->{NickName} ) } = $record;
    $self->{byserver}->{ $server }->{ u_irc ( $record->{NickName} ) } = $record;
  }
		   
  return 1;
}

sub _nick_del {
  my ($self) = shift;
  my ($nickname) = u_irc ( $_[0] ) || return 0;

  foreach ( keys %{ $self->{bynickname}->{$nickname}->{Channels} } ) {
    delete ( $self->{channels}->{$_}->{Members}->{$nickname} );
    if ( scalar ( keys % { $self->{channels}->{$_}->{Members} } ) == 0 ) {
	delete ( $self->{channels}->{$_} );
    }
  }
  my ($server) = $self->{bynickname}->{$nickname}->{Server};
  delete ( $self->{bynickname}->{$nickname} );
  delete ( $self->{byserver}->{$server}->{$nickname} );
  return 1;
}

sub _nick_change {
  my ($self) = shift;
  my ($nickname) = u_irc ( $_[0] ) || return 0;
  my ($newnick) = $_[1] || return 0;

  my ($record) = $self->{bynickname}->{$nickname};
  $record->{NickName} = $newnick;
  $record->{TimeStamp} = time();
  delete $self->{bynickname}->{$nickname};
  $self->{bynickname}->{ u_irc( $record->{NickName} ) } = $record;
  return 1;
}

sub _nick_umode {
  my ($self) = shift;
  my ($nickname) = u_irc ( $_[0] ) || return 0;
  my ($umode) = $_[1] || return 0;

  my ($currentumode) = $self->{bynickname}->{$nickname}->{UMode};
  foreach (retOpflags($umode)) {
    SWITCH: {
      if (/^\+(.+)/) {
	if ( not defined ($currentumode) ) {
	  $currentumode = $1;
	} else {
	  $currentumode .= $1;
	  $currentumode = join("",sort(split(//,$currentumode)));
	}
	last SWITCH;
      }
      if (/^-(.+)/) {
	if ( defined ($currentumode) ) {
	  $currentumode =~ s/$1//g;
	}
	last SWITCH;
      }
    }
  }
  if ( defined ($currentumode) and $currentumode ) {
    $self->{bynickname}->{$nickname}->{UMode} = $currentumode;
  } else {
    delete ( $self->{bynickname}->{$nickname}->{UMode} );
  }
  return 1;
}

sub _channel_join {
  my ($self) = shift;
  my ($channel) = $_[0] || return 0;
  my ($nickname) = u_irc ( $_[1] ) || return 0;
  my ($timestamp) = $_[2];
  my ($usermode) = 0;
  my ($channelname) = $channel;
  $channel = u_irc ( $channel );
  
  if (not exists $self->{channels}->{$channel}) {
    $self->{channels}->{$channel}->{Channel} = $channelname;
    $self->{channels}->{$channel}->{TimeStamp} = $timestamp;
    $usermode = 2;
  }
  $self->{channels}->{$channel}->{Members}->{$nickname} = $usermode;
  $self->{bynickname}->{$nickname}->{Channels}->{$channel} = $usermode;
  return 1;
}

sub _channel_part {
  my ($self) = shift;
  my ($channel) = u_irc ( $_[0] ) || return 0;
  my ($nickname) = u_irc ( $_[1] ) || return 0;

  delete ( $self->{channels}->{$channel}->{Members}->{$nickname} );
  if ( scalar ( keys % { $self->{channels}->{$_}->{Members} } ) == 0 ) {
    delete ( $self->{channels}->{$_} );
  }
  delete ( $self->{bynickname}->{$nickname}->{Channels}->{$channel} );
  return 1;
}

sub _channel_topic {
  my ($self) = shift;
  my ($channel) = u_irc( $_[0] ) || return 0;
  my ($topic) = $_[1] || return 0;
  my ($set_by) = $_[2] || return 0;
  my ($timestamp) = $_[3] || return 0;

  $self->{channels}->{$channel}->{Topic} = $topic;
  $self->{channels}->{$channel}->{Set_By} = $set_by;
  $self->{channels}->{$channel}->{TopicTS} = $timestamp;
  return 1;
}

sub _channel_untopic {
  my ($self) = shift;
  my ($channel) = u_irc( $_[0] ) || return 0;

  delete ( $self->{channels}->{$channel}->{Topic} );
  delete ( $self->{channels}->{$channel}->{Set_By} );
  delete ( $self->{channels}->{$channel}->{TopicTS} );
  return 1;
}

sub _channel_mode {
  my ($self) = shift;
  my ($channel) = u_irc( $_[0] ) || return 0;
  my ($string) = $_[1] || return 0;
  my ($who) = $_[2] || return 0; # This is either a server or client name only used for bans tbh

  my ($modes,@args) = split(/ /,$string);
  my (@modes) = retOpflags($modes);
  my ($currentmode) = $self->{channels}->{$channel}->{Mode};
  foreach (@modes) {
    my $argument;
    $argument = shift(@args) if (/\+[bkloveIh]/);
    $argument = shift(@args) if (/-[boveIh]/);
    SWITCH: {
      if (/[eI]/) {
	last SWITCH;
      }
      if (/b/) {
	$self->_channel_ban($channel,$_,$argument,$who);
	last SWITCH;
      }
      if (/l/) {
	if (/^\+(.+)/) {
	  $self->{channels}->{$channel}->{ChanLimit} = $argument;
	  $currentmode .= $1;
	} else {
	  delete ( $self->{channels}->{$channel}->{ChanLimit} );
	  $currentmode =~ s/$1//g;
	}
	last SWITCH;
      }
      if (/k/) {
	if (/^\+(.+)/) {
	  $self->{channels}->{$channel}->{ChanKey} = $argument;
	  $currentmode .= $1;
	} else {
	  delete ( $self->{channels}->{$channel}->{ChanKey} );
	  $currentmode =~ s/$1//g;
	}
	last SWITCH;
      }
      if (/[ov]/) {
	my ($value) = 0;
	if (/\+o/) { $value = 2; }
	if (/-o/) { $value = -2; }
	if (/\+v/) { $value = 1; }
	if (/-v/) { $value = -1; }
        $self->{channels}->{$channel}->{Members}->{$argument} += $value;
        $self->{bynickname}->{ u_irc ( $argument ) }->{Channels}->{$channel} += $value;
	last SWITCH;
      }
      if (/[h]/) {
        if (/\+h/) {
          $self->{channels}->{$channel}->{Members}->{$argument} = -1;
          $self->{bynickname}->{ u_irc ( $argument ) }->{Channels}->{$channel} = -1;
        } else {
          $self->{channels}->{$channel}->{Members}->{$argument} = 0;
          $self->{bynickname}->{ u_irc ( $argument ) }->{Channels}->{$channel} = 0;
        }
	last SWITCH;
      }
      if (/^\+(.+)/) {
	$currentmode .= $1;
	last SWITCH;
      }
      if (/^-(.+)/) {
	$currentmode =~ s/$1//g;
	last SWITCH;
      }
    }
  }
  $self->{channels}->{$channel}->{Mode} = join("",sort(split(//,$currentmode)));
  return 1;
}

sub _channel_ban {
  my ($self) = shift;
  my ($channel) = u_irc( $_[0] ) || return 0;
  my ($operation) = $_[1] || return 0;
  my ($banmask) = $_[2] || return 0;
  my ($who) = $_[3] || return 0;
 
  if ($operation eq "+b") { 
    $self->{channels}->{$channel}->{Bans}->{$banmask}->{Time} = time();
    $self->{channels}->{$channel}->{Bans}->{$banmask}->{Who} = $who;
  } else {
    delete ( $self->{channels}->{$channel}->{Bans}->{$banmask} );
  }
  return 1;
}

sub _channel_burst {
  my ($self) = shift;
  my ($args) = shift || return 0;

  my ($first,$second) = split(/ :/,$args);
  my (@args) = split(/ /,$first); my (@nicknames) = split(/ /,$second);
  my ($timestamp,$channelname) = @args[0..1];
  my ($channel) = u_irc ( $channelname );
  if ( exists $self->{channels}->{$channel} and $timestamp < $self->{channels}->{$channel}->{TimeStamp} ) {
    $self->{channels}->{$channel}->{TimeStamp} = $timestamp;
    $self->{burst_channels}->{$channel}->{TimeStamp} = $timestamp;
  } else {
    $self->{channels}->{$channel}->{Channel} = $channelname;
    $self->{channels}->{$channel}->{TimeStamp} = $timestamp;
  }
  if ( $args[2] =~ /^\+(.+)$/ ) {
    $self->{channels}->{$channel}->{Mode} = $1;
    my ($l) = index ( $1, "l" );
    my ($k) = index ( $1, "k" );
    SWITCH: {
      if ( $l > $k and $k != -1 ) {
	$self->{channels}->{$channel}->{ChanLimit} = $args[4];
	$self->{channels}->{$channel}->{ChanKey} = $args[3];
	last SWITCH;
      }
      if ( $l > $k and $k == -1 ) {
	$self->{channels}->{$channel}->{ChanLimit} = $args[3];
	last SWITCH;
      }
      if ( $k > $l and $l != -1 ) {
	$self->{channels}->{$channel}->{ChanLimit} = $args[3];
	$self->{channels}->{$channel}->{ChanKey} = $args[4];
	last SWITCH;
      }
      if ( $k > $l and $l == -1 ) {
	$self->{channels}->{$channel}->{ChanKey} = $args[3];
	last SWITCH;
      }
    }
  }
  foreach ( @nicknames ) {
    my ($value) = 0; my ($nickname);
    if ( /^(\@|\+|%)+(.*)/ ) {
      if ( $1 =~ /\@/ ) {
        $value += 2;
      }
      if ( $1 =~ /\+/ ) {
        $value += 1;
      }
      if ( $1 =~ /%/ ) {
        $value = -1;
      }
      $nickname = $2;
    } else {
      $nickname = $_;
    }
    $self->{channels}->{$channel}->{Members}->{ u_irc ( $nickname ) } = $value;
    $self->{bynickname}->{ u_irc ( $nickname ) }->{Channels}->{$channel} = $value;
  }
}

sub _burst_create {
  my ($self) = shift;

  foreach ( keys %{ $self->{bynickname} } ) {
    $self->{burst_nicks}->{$_}->{NickName} = $self->{bynickname}->{$_}->{NickName};
    $self->{burst_nicks}->{$_}->{UserName} = $self->{bynickname}->{$_}->{UserName};
    $self->{burst_nicks}->{$_}->{HostName} = $self->{bynickname}->{$_}->{HostName};
    $self->{burst_nicks}->{$_}->{IRCName} = $self->{bynickname}->{$_}->{IRCName};
    $self->{burst_nicks}->{$_}->{TimeStamp} = $self->{bynickname}->{$_}->{TimeStamp};
    $self->{burst_nicks}->{$_}->{Server} = $self->{bynickname}->{$_}->{Server};
    $self->{burst_nicks}->{$_}->{UMode} = $self->{bynickname}->{$_}->{UMode};
  }
  foreach ( keys %{ $self->{channels} } ) {
    $self->{burst_channels}->{$_}->{Channel} = $self->{channels}->{$_}->{Channel};
    $self->{burst_channels}->{$_}->{TimeStamp} = $self->{channels}->{$_}->{TimeStamp};
    $self->{burst_channels}->{$_}->{Mode} = $self->{channels}->{$_}->{Mode};
    $self->{burst_channels}->{$_}->{ChanKey} = $self->{channels}->{$_}->{ChanKey} if ( defined ( $self->{channels}->{$_}->{ChanKey} ) );
    $self->{burst_channels}->{$_}->{ChanLimit} = $self->{channels}->{$_}->{ChanLimit} if ( defined ( $self->{channels}->{$_}->{ChanLimit} ) );
    foreach my $ban ( keys %{ $self->{channels}->{$_}->{Bans} } ) {
	push( @{ $self->{burst_channels}->{$_}->{Bans} }, $ban );
    }
    foreach my $user ( keys %{ $self->{channels}->{$_}->{Members} } ) {
	$self->{burst_channels}->{$_}->{Members}->{$user} = $self->{channels}->{$_}->{Members}->{$user};
    }
  }
  return 1;
}

sub _burst_info {
  my ($self) = shift;
  my (@burst);
  my (@modes) = ( '', '+', '@', '@+' );

  # Nicknames first
  foreach ( keys %{ $self->{burst_nicks} } ) {
    my ($burstline) = "NICK " . $self->{burst_nicks}->{$_}->{NickName} . " ";
    $burstline .= "1 " . $self->{burst_nicks}->{$_}->{TimeStamp} . " ";
    $burstline .= $self->{burst_nicks}->{$_}->{UserName} . " " . $self->{burst_nicks}->{$_}->{HostName} . " " . $self->{burst_nicks}->{$_}->{Server} . " :";
    $burstline .= $self->{burst_nicks}->{$_}->{IRCName} if ( defined ( $self->{burst_nicks}->{$_}->{IRCName} ) );
    push (@burst, $burstline);
  }
  foreach ( keys %{ $self->{burst_channels} } ) { 
    my ($burstline) = "SJOIN " . $self->{burst_channels}->{$_}->{TimeStamp} . " " . $self->{burst_channels}->{$_}->{Channel} . " +";
    $burstline .= $self->{burst_channels}->{$_}->{Mode} if ( defined ( $self->{burst_channels}->{$_}->{Mode} ) );
    $burstline .= " " . $self->{burst_channels}->{$_}->{ChanKey} if ( defined ( $self->{burst_channels}->{$_}->{ChanKey} ) );
    $burstline .= " " . $self->{burst_channels}->{$_}->{ChanLimit} if ( defined ( $self->{burst_channels}->{$_}->{ChanLimit} ) );
    $burstline .= " :"; my (@users);
    foreach my $i ( keys %{ $self->{burst_channels}->{$_}->{Members} } ) {
      if ( $self->{burst_channels}->{$_}->{Members}->{$i} == -1 ) {
        push ( @users, "%" . $self->{burst_nicks}->{$i}->{NickName} );
      } else {
        push ( @users, $modes[ $self->{burst_channels}->{$_}->{Members}->{$i} ] . $self->{burst_nicks}->{$i}->{NickName} );
      }
    }
    $burstline .= join(" ", @users);
    push (@burst, $burstline);
    my ($bans) = join(" ", @{ $self->{burst_channels}->{$_}->{Bans} });
    if ( defined ($bans) ) {
      $burstline = "MODE " . $self->{burst_channels}->{$_}->{Channel} . " +";
      for (my $i = 0; $i <= $#{ $self->{burst_channels}->{$_}->{Bans} }; $i++) {
        $burstline .= "b";
      }
      $burstline .= " $bans";
      push (@burst, $burstline);
    }
  }
  return @burst;
}

sub _burst_destroy {
  my ($self) = shift;

  delete ( $self->{burst_nicks} );
  delete ( $self->{burst_channels} );
}

# Public Methods

1;
__END__
# POD should be next :)

=head1 NAME

POE::Component::IRC::Service::Hybrid - a fully event-driven IRC services module for Hybrid networks.

=head1 SYNOPSIS

  use POE::Component::IRC::Service::Hybrid;

  # Do this when you create your sessions. 'IRC-Service' is just a
  # kernel alias to christen the new IRC connection with. (Returns
  # only a true or false success flag, not an object.)

  POE::Component::IRC::Service::Hybrid->new('IRC-Service') or die "Oh noooo! $!";

  # Do stuff like this from within your sessions. This line tells the
  # connection named "IRC-Service" to send your session the following
  # events when they happen.

  $kernel->post('IRC-Service', 'register', qw(connected msg public nick server));

  # You can guess what this line does.

  $kernel->post('IRC-Service', 'connect',
                { ServerName        => 'services.lamenet.org',
                  ServerDesc        => 'Services for LameNET',
                  RemoteServer      => 'hub.lamenet.org',
                  ServerPort        => 7666,
                  Password          => 'password', } );

  # Add a services identity to the network

  $kernel->post('IRC-Service' => 'addnick',
                { NickName    => 'Lame',
                  Umode       => '+o',
                  Description => 'Lame Services Bot', } );

=head1 DESCRIPTION

POE::Component::IRC::Service::Hybrid is a POE component which
acts as an easily controllable IRC Services client for your other POE
components and sessions. You create an IRC Services component and tell it what
events your session cares about and where to connect to, and it sends
back interesting IRC events when they happen. You make the client do
things by sending it events.

[Note that this module requires a lot of familiarity with the details of the
IRC protocol. I'd advise you to read up on the gory details of RFC 1459 
E<lt>http://cs-pub.bu.edu/pub/irc/support/rfc1459.txtE<gt> before starting.
Some knowledge of the Hybrid's IRC Server-to-Server protocol would also be advisable, most importantly
with TSora. Check out the documents that come with the Hybrid IRCd package.

So you want to write a POE program with POE::Component::IRC::Service::Hybrid? 
Listen up. The short version is as follows: Create your session(s) and an
alias for a new POE::Component::IRC::Service::Hybrid client. (Conceptually, it helps if
you think of them as little IRC servers.) In your session's _start
handler, send the IRC service a 'register' event to tell it which IRC
events you want to receive from it. Send it a 'connect' event at some
point to tell it to join the IRC network, and it should start sending you
interesting events every once in a while. Use the 'addnick' event to add
an IRC client to your "server". The IRC Service accepts two different sets of
events, server and client. Server events are commands that are issued by (heh) 
the server and client events are commands issued by clients.

  # Example of a client command:

  $kernel->post( 'IRC-Service', 'join', 'Lame' , '#LameNET' );

  # Example of a server command:

  $kernel->post( 'IRC-Service', 'sl_server', "MODE #LameNET +o Lame" );

Basically, client commands require a source nickname for the command, eg. 
it doesn't make sense for a server to "join" a channel.

The long version is the rest of this document.

=head1 METHODS

Well, OK, there's only actually one, so it's more like "METHOD".

=over

=item new

Takes two arguments: a name (kernel alias) which this new connection
will be known by, the second argument is a hashref of options see C<connect> for more
details. B<WARNING:> This method, for all that it's named
"new" and called in an OO fashion, doesn't actually return an
object. It returns a true or false value which indicates if the new
session was created or not. If it returns false, check $! for the
POE::Session error code.

=back

=head1 INPUT

How to talk to your new IRC Services component... here's the events we'll accept.

=head2 Important Commands

=over

=item connect

Takes one argument: a hash reference of attributes for the new
connection (see the L<SYNOPSIS> section of this doc for an
example). This event tells the IRC Services client to connect to a
new/different hub and join an IRC network. If it has a connection already open, it'll close
it gracefully before reconnecting. Possible attributes for the new
connection are "ServerName", the name your IRC Service will
be called; "ServerDesc", a brief description of your IRC Service; "RemoteServer", the DNS or
IP address of your uplink/hub server; "ServerPort", the port to connect to on your uplink/hub 
server; "Password", the password required to link to uplink/hub server; "LocalAddr", 
which local IP address on a multihomed box to connect as; "EOB", set to '0' to disable automatic
generation of an End of Burst. 

=item addnick

Takes one argument: a hash reference of attributes for the new service client 
(see the L<SYNOPSIS> section of this doc for an example). This event adds a new 
client to the IRC Service server. Multiple clients are allowed. Expect to receive
an appropriate irc_hyb_nick event for the new client, from which you can derive the 
clients numeric token. Possible attributes for the new client are "NickName", (duh) 
the nickname this client will appear as on the IRC network (only required attribute); 
"UserName", the user part of ident@host (default is nick); 
"HostName", the host part of ident@host (default is the name of the server);
"Umode", the user modes this client will have (defaults to +odk);
"Description", equivalent to the IRCName (default server description);

=item register

Takes N arguments: a list of event names that your session wants to
listen for, minus the "irc_hyb_" prefix. So, for instance, if you just
want a bot that keeps track of which people are on a channel, you'll
need to listen for CREATEs, JOINs, PARTs, QUITs, and KICKs to people on the
channel you're in. You'd tell POE::Component::IRC::Service::Hybrid that you want those
events by saying this:

  $kernel->post( 'IRC-Service', 'register', qw(join part quit kick) );

Then, whenever people enter or leave a channel (forcibly
or not), your session will receive events with names like "irc_hyb_join",
"irc_hyb__kick", etc., which you can use to update a list of people on the
channel.

Registering for C<'all'> will cause it to send all IRC-related events to
you; this is the easiest way to handle it.

=item unregister

Takes N arguments: a list of event names which you I<don't> want to
receive. If you've previously done a 'register' for a particular event
which you no longer care about, this event will tell the IRC
connection to stop sending them to you. (If you haven't, it just
ignores you. No big deal.)

=back

=head2 Server initiated commands

These are commands that come from the IRC Service itself and not from clients.

=over

=item gline

Sets or removes a GLINE to the IRC network. A GLINE prevents matching users from connecting to the
network. Implemented as if the IRC Service is a U: lined server, so ircd must be configured 
accordingly. Takes four arguments, the target for the gline which can be * (for all servers) or
a server numeric; the mask to gline [!][-|+]<mask> the presence of the ! prefix means "force", 
+ means add/activate, - means remove/deactivate; the duration of the gline, ie. the time to expire the
gline in seconds since epoch ( ie. output from time() ); the reason for the gline.
Mask may be a user@host mask, or a channel name. In the later case (mask starts with a # or &) it is a "BADCHAN". 
A BADCHAN prevents users from joining a channel with the same name.

=item jupe

A jupe prevents servers from joining the network. Takes five arguments, the target for the jupe,
either * for all servers or a server numeric; what to jupe [!][-|+]<server>, ! is force, + activate jupe, 
- deactivate jupe; the duration of the jupe, ie. the time to expire the jupe in seconds since epoch; the
last modification timestamp, ie. the output of time(); the reason for the jupe.

=item kill

Server kill :) Takes two arguments, the client numeric of the victim; the reason for the kill.
If the numeric specified matches one of the IRC Service's internal clients, that client will
be automatically removed.

=item squit

This will disconnect the IRC Service from its uplink/hub server. Expect to receive an
"irc_hyb_disconnected" event. Takes no arguments.

=item sl_server

Send a raw server command. Exercise extreme caution. Takes one argument, a string 
representing the raw command that the server will send. The module prepends the
appropriate server numeric for you, so don't worry about that. Note, IRC commands must be 
specified as tokenised equivalents as per P10 specification.

$kernel->post( 'IRC-Service' => sl_server => "MODE #LameNET +o Lame" );

=back

=head2 Client initiated commands

These are commands that come from clients on the IRC Service.

=over

=item ctcp and ctcpreply

Sends a CTCP query or response to the nick(s) or channel(s) which you
specify. Takes 3 arguments: the numeric of the client who is sending the command;
the nickname or channel to send a message to
(use an array reference here to specify multiple recipients), and the
plain text of the message to send (the CTCP quoting will be handled
for you).

=item invite

Invites another user onto an invite-only channel. Takes 3 arguments:
the numeric of the inviting client, the nick of the user you wish to admit, 
and the name of the channel to invite them to.

=item join

Tells a specified client to join a single channel of your choice. Takes
at least two args: the numeric of the client that you want to join, 
the channel name (required) and the channel key
(optional, for password-protected channels).

=item mode

Request a mode change on a particular channel or user. Takes at least
two arguments: the mode changing client's nickname, 
the mode changes to effect, as a single string (e.g.,
"+sm-p+o"), and any number of optional operands to the mode changes
(nicknames, hostmasks, channel keys, whatever.) Or just pass them all as one
big string and it'll still work, whatever.

=item nick

Allows you to change a client's nickname. Takes two arguments: the 
nickname of the client who wishes to change nickname and the
new username that you'd like to be known as.

=item notice

Sends a NOTICE message to the nick(s) or channel(s) which you
specify. Takes 3 arguments: the nickname of the issuing client, 
the nick or channel to send a notice to
(use an array reference here to specify multiple recipients), and the
text of the notice to send.

=item part

Tell a client to leave the channels which you pass to it. Takes
any number of arguments: the nickname of the client followed by the 
channel names to depart from.

=item privmsg

Sends a public or private message to the nick(s) or channel(s) which
you specify. Takes 3 arguments: the nickname of the issuing client, 
the numeric or channel to send a message
to (use an array reference here to specify multiple recipients), and
the text of the message to send.

=item quit

Tells the IRC service to remove a client. Takes one argument: 
the nickname of the client to disconnect; and one optional argument:
some clever, witty string that other users in your channels will see
as you leave. The IRC Service will automatically remove the client from
its internal list of clients.

=item sl_client

Send a raw client command. Exercise extreme caution. Takes one argument, a string 
representing the raw command that the server will send. Unlike "sl_server" you must specify 
the full raw command prefixed with the appropriate client nickname.

$kernel->post( 'IRC-Service' => sl_client => ":Lame MODE #LameNET +o Lame2" );

=item stats

Returns some information about a server. Kinda complicated and not
terribly commonly used, so look it up in the RFC if you're
curious. Takes as many arguments as you please, but the first argument
must be the nickname of a client.

=back

=head1 OUTPUT

The events you will receive (or can ask to receive) from your running
IRC component. Note that all incoming event names your session will
receive are prefixed by "irc_hyb_", to inhibit event namespace pollution
( and Dennis had already taken irc_ :p ).

If you wish, you can ask the client to send you every event it
generates. Simply register for the event name "all". This is a lot
easier than writing a huge list of things you specifically want to
listen for.

The IRC Service deals with some events on your behalf, they will be duly noted
below.

=head2 Important Events

=over

=item irc_hyb_connected

The IRC component will send an "irc_hyb_connected" event as soon as it
establishes a connection to an IRC server, before attempting to log
in. ARG0 is whatever you passed to "connect" as RemoteServer.

B<NOTE:> When you get an "irc_hyb_connected" event, this doesn't mean you
can start sending commands to the server yet. The uplink/hub server and the IRC 
Service will be in the process of synchronising by way of a net burst. Wait for 
an "irc_hyb_eob" from your uplink/hub server before sending any events.

=item irc_hyb_sjoin

This event is generated during a net burst when the IRC Service first joins an 
IRC network. It is basically a description of a channel and its state, ie. nicks, modes, bans, etc.
See TSora specification for the gory details. This is also what servers use to propogate channel JOINS, 
don't expect to see irc_hyb_join events :( 

=item irc_hyb_server_link

This is the response from the uplink/hub server we connected to. You can use this event
to discern the server numeric of the server we are connected to. ARG0 is server's name, ARG1 is
the hop count, ARG2 is the server description.

=item irc_hyb_svinfo

This follows an irc_hyb_server_link and tells you what version of TSora the uplink can do and its timestamp. ARG0 is 
highest version of TSora the uplink will do and ARG1 is the lowest version. ARG2 is the timestamp from the uplink.
=item irc_hyb_server

Seen during a net burst and when a new server joins the network. ARG0 is the server name.
ARG1 is a single string made up of the data for the server, which has the following format <name> <hop> <boot-ts> <link-ts> <protocol> <max-clients> :<description>. See Hint above in irc_hyb_server-link.

=item irc_hyb_end_of_burst

Sent by a server when it finishes a net burst. The module will automatically respond to an end of burst by its uplink/hub with an
end_of_burst_ack. The module will also automatically send its own end_of_burst message to the uplink/hub unless you set the appropriate
option during CONNECT ( See above ).

=item irc_hyb_squit

Received when a server disconnects. ARG0 is the server numeric of the sender. ARG1 is a string with the data of the event, with the
following format: <servername> <timestamp> :<description>

=item irc_hyb_stats

The module takes care of "u" requests automagically.

=item irc_hyb_ping

The module takes care of ponging to these automagically.

=item Miscellaneous events

Events such as join, part, etc. should be same as POE::Component::IRC. See that documentation for details.

=item All numeric events (see RFC 1459)

Most messages from IRC servers are identified only by three-digit
numeric codes with undescriptive constant names like RPL_UMODEIS and
ERR_NOTOPLEVEL. (Actually, the list of codes in the RFC is kind of
out-of-date... the list in the back of Net::IRC::Event.pm is more
complete, and different IRC networks have different and incompatible
lists. Ack!) As an example, say you wanted to handle event 376
(RPL_ENDOFMOTD, which signals the end of the MOTD message). You'd
register for '376', and listen for 'irc_hyb_376' events. Simple, no? ARG0
is the numeric of the server which sent the message. ARG1 is the text of
the message.

=back

=head1 AUTHOR

Chris Williams, E<lt>chris@bingosnet.co.uk<gt>

Based on a hell of lot of POE::Component::IRC written by
Dennis Taylor, E<lt>dennis@funkplanet.comE<gt>

=head1 LICENSE

Copyright (c) Dennis Taylor and Chris Williams.

This module may be used, modified, and distributed under the same
terms as Perl itself. Please see the license that came with your Perl
distribution for details.

=head1 MAD PROPS

Greatest of debts to Dennis Taylor, E<lt>dennis@funkplanet.comE<gt> for
letting me "salvage" POE::Component::IRC to write this module.

And to ^kosh and FozzySon and others from #jeditips for allowing me to 
inflict my coding on them :)

=head1 SEE ALSO

RFC 1459, http://www.irchelp.org/, http://poe.perl.org/,
http://www.xs4all.nl/~beware3/irc/bewarep10.html


=cut


# POE::Component::Client::FTP
#
# Author      : Michael Ching
# Email       : michaelc@wush.net
# Created     : May 15, 2002
# Description : An FTP client for POE

package POE::Component::Client::FTP;
$POE::Component::Client::FTP::VERSION = '0.24';
#ABSTRACT: Implements an FTP client POE Component

use strict;
use warnings;

use Carp;
use Exporter;
use Socket;
# use Data::Dumper;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite
	   Filter::Stream Filter::Line Driver::SysRW);

use vars qw(@ISA @EXPORT $poe_kernel);

@ISA = qw(Exporter);
@EXPORT = qw(FTP_PASSIVE FTP_ACTIVE FTP_MANUAL FTP_ASCII FTP_BINARY);

BEGIN {
  eval 'sub DEBUG         () { 0 }' unless defined &DEBUG;
  eval 'sub DEBUG_COMMAND () { 0 }' unless defined &DEBUG_COMMAND;
  eval 'sub DEBUG_DATA () { 0 }'    unless defined &DEBUG_DATA;
}

sub EOL         () { "\015\012" }

# connection modes
sub FTP_PASSIVE () { 1 }
sub FTP_ACTIVE  () { 2 }

# transfer modes
sub FTP_MANUAL  () { 0 }
sub FTP_ASCII   () { 1 }
sub FTP_BINARY  () { 2 }

# tells the dispatcher which states support which events
my $state_map =
  { _init  => { "_start"            => \&do_init_start,
		"connect"           => \&do_init_start,
		"cmd_connected"     => \&handler_init_connected,
		"cmd_connect_error" => \&handler_init_error,
		"success"           => \&handler_init_success,
		"timeout"           => \&handler_init_error
	      },

    stop   => { "_start" => \&do_stop
	      },

    authtls => { "authtls"  => \&do_send_authtls,
                 "success"  => \&handler_authtls_success,
                 "failure"  => \&handler_authtls_failure
              },

    login  => { "login"        => \&do_login_send_username,
		"intermediate" => \&do_login_send_password,
		"success"      => \&handler_login_success,
		"failure"      => \&handler_login_failure
	      },

    pbsz_prot => { "pbsz"    => \&do_send_pbsz,
                   "prot"    => \&do_send_prot,
                   "success" => \&handler_pbsz_prot_success,
                   "failure" => \&handler_pbsz_prot_failure
              },

    global => { "cmd_input" => \&handler_cmd_input,
		"cmd_error" => \&handler_cmd_error
	      },

    ready  => { "_start" => \&dequeue_event,
		rename   => \&do_rename,
		put      => \&do_put,

		map ( { $_ => \&do_simple_command }
		      qw{ cd cdup delete mdtm mkdir noop
			  pwd rmdir site size stat syst type quit quot }
		    ),

		map ( { $_ => \&do_complex_command }
		      qw{ dir ls get }
		    ),

		map ( { $_ => \&do_set_attribute }
			qw{ trans_mode conn_mode blocksize timeout }
		    ),
	      },

    put => { data_flush         => \&handler_put_flushed,
	     data_error         => \&handler_put_data_error,

       put_data           => \&do_put_data,
	     put_close          => \&do_put_close,

	     data_connected     => \&handler_complex_connected,
	     data_connect_error => \&handler_complex_connect_error,
	     preliminary        => \&handler_complex_preliminary,
	     success            => \&handler_complex_success,
	     failure            => \&handler_complex_failure,
	   },

    rename => { "intermediate" => \&handler_rename_intermediate,
		"success"      => \&handler_rename_success,
		"failure"      => \&handler_rename_failure
	      },

    default_simple  => { "success" => \&handler_simple_success,
			 "failure" => \&handler_simple_failure
		       },

    default_complex => { data_connected     => \&handler_complex_connected,
			 data_connect_error => \&handler_complex_connect_error,
			 data_flush         => \&handler_complex_flushed,
			 preliminary        => \&handler_complex_preliminary,
			 success            => \&handler_complex_success,
			 failure            => \&handler_complex_failure,
			 data_input         => \&handler_complex_list_data,
			 data_error         => \&handler_complex_list_error
		       },
  };

# translation from posted signals to ftp commands
my %command_map  = ( CD    => "CWD",
		     MKDIR => "MKD",
		     RMDIR => "RMD",

		     LS  => "LIST",
		     DIR => "NLST",
		     GET => "RETR",

		     PUT => "STOR",

		     DELETE => "DELE",
		   );

# create a new POE::Component::Client::FTP object
sub spawn {
  my $class = shift;
  my $sender = $poe_kernel->get_active_session;

  croak "$class->spawn requires an event number of argument" if @_ & 1;

  my %params = @_;

  my $alias = delete $params{Alias};
  croak "$class->spawn requires an alias to start" unless defined $alias;

  my $user = delete $params{Username};
  my $pass = delete $params{Password};

  my $local_addr = delete $params{LocalAddr};
  $local_addr = INADDR_ANY unless defined $local_addr;

  my $local_port = delete $params{LocalPort};
  $local_port = 0 unless defined $local_port;

  my $remote_addr = delete $params{RemoteAddr};
  croak "$class->spawn requires a RemoteAddr parameter"
    unless defined $remote_addr;

  my $remote_port = delete $params{RemotePort};
  $remote_port = 21 unless defined $remote_port;

  my $tlscmd = delete $params{TLS};
  $tlscmd = 0 unless defined $tlscmd;

  my $tlsdata = delete $params{TLSData};
  $tlsdata = 0 unless defined $tlsdata;

  my $timeout = delete $params{Timeout};
  $timeout = 120 unless defined $timeout;

  my $blocksize = delete $params{BlockSize};
  $blocksize = 10240 unless defined $blocksize;

  my $conn_mode = delete $params{ConnectionMode};
  $conn_mode = FTP_PASSIVE unless defined $conn_mode;

  my $trans_mode = delete $params{TransferMode};
  $trans_mode = FTP_MANUAL unless defined $trans_mode;

  my $filters = delete $params{Filters};
  $filters->{dir} ||= new POE::Filter::Line( Literal => EOL );
  $filters->{ls}  ||= new POE::Filter::Line( Literal => EOL );
  $filters->{get} ||= new POE::Filter::Stream();
  $filters->{put} ||= new POE::Filter::Stream();

  my $events = delete $params{Events};
  $events = [] unless defined $events and ref( $events ) eq 'ARRAY';
  my %register;
  for my $opt ( @$events ) {
    if ( ref $opt eq 'HASH' ) {
      @register{keys %$opt} = values %$opt;
    } else {
      $register{$opt} = $opt;
    }
  }

  # Make sure the user didn't make a typo on parameters
  carp "Unknown parameters: ", join( ', ', sort keys %params )
    if keys %params;

  if ( $tlscmd || $tlsdata ) {
    eval {
       require POE::Component::SSLify;
       import POE::Component::SSLify qw( Client_SSLify );
    };

    if ($@) {
	warn "TLS option specified, but there was a problem\n";
	$tlscmd = 0; $tlsdata = 0;
    }
  }

  my $self = bless {
      alias           => $alias,
      user            => $user,
      pass            => $pass,
      local_addr      => $local_addr,
      local_port      => $local_port,
      remote_addr     => $remote_addr,
      remote_port     => $remote_port,

      tlscmd          => $tlscmd,
      tlsdata         => $tlsdata,
      attr_trans_mode => $trans_mode,
      attr_conn_mode  => $conn_mode,
      attr_timeout    => $timeout,
      attr_blocksize  => $blocksize,

      cmd_sock_wheel  => undef,
      cmd_rw_wheel    => undef,

      data_sock_wheel => undef,
      data_rw_wheel   => undef,
      data_sock_port  => 0,
      data_suicidal   => 0,

      filters         => $filters,

      state           => "_init",
      queue           => [ ],

      stack           => [ [ 'init' ] ],
      event           => [ ],

      complex_stack   => [ ],

      events          => { $sender => \%register }
  }, $class;

  $self->{session_id} = POE::Session->create (
    inline_states => map_all($state_map, \&dispatch),

    heap => $self,
  )->ID();
  return $self;
}

# connect to address specified during spawn
sub do_init_start {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  $heap->{session_id} = $session->ID();
  # set timeout for connection
  $kernel->delay( "timeout", $heap->{attr_timeout}, undef, undef, "Timeout ($heap->{attr_timeout} seconds)" );

  # connect to command port
  $heap->{cmd_sock_wheel} = POE::Wheel::SocketFactory->new(
    SocketDomain   => AF_INET,
    SocketType     => SOCK_STREAM,
    SocketProtocol => 'tcp',
    RemotePort     => $heap->{remote_port},
    RemoteAddress  => $heap->{remote_addr},
    SuccessEvent   => 'cmd_connected',
    FailureEvent   => 'cmd_connect_error'
  );

  $kernel->alias_set( $heap->{alias} );
  return;
}

# try to clean up
# client responsibility to ensure things are all complete
sub do_stop {
  my $heap = $poe_kernel->get_active_session()->get_heap();

  warn "cleaning up" if DEBUG;

  delete $heap->{cmd_rw_wheel};
  delete $heap->{cmd_sock_wheel};
  clean_up_complex_cmd();

  $poe_kernel->alias_remove( $heap->{alias} );
  return;
}

# server responses on command connection
sub handler_cmd_input {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  warn "<<< $input\n" if DEBUG_COMMAND;

  my $coderef;

  my ($code, $more) = parse_cmd_string(\$input);

  $input =~ s/^ // if defined $more && $more eq "-";

  $heap->{ftp_message} .= "$input\n";

  return unless defined $code && defined $more && $more eq " ";

  $heap->{ftp_message} =~ s/\s+$//;

  my $major = substr($code, 0, 1);

  if ($major == 1) {
    # 1yz   Positive Preliminary reply

    $coderef = $state_map->{ $heap->{state} }{preliminary};
  }
  elsif ($major == 2) {
    # 2yz   Positive Completion reply

    $coderef = $state_map->{ $heap->{state} }{success};
    $heap->{event} = pop( @{$heap->{stack}} ) || ['none', {}];
  }
  elsif ($major == 3) {
    # 3yz   Positive Intermediate reply

    $coderef = $state_map->{ $heap->{state} }{intermediate};
    $heap->{event} = pop( @{$heap->{stack}} ) || ['none', {}];
  }
  else {
     # 4yz   Transient Negative Completion reply
     # 5yz   Permanent Negative Completion reply

    $coderef = $state_map->{ $heap->{state} }{failure};
    $heap->{event} = pop( @{$heap->{stack}} ) || ['none', {}];
  }

  &{ $coderef }(@_) if $coderef;
  delete $heap->{ftp_message};
  return;
}


# command connection closed
sub handler_cmd_error {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  goto_state("stop");
  return;
}

## state specific

## rename state

# initiate multipart rename command
# uses the complex_stack to remember what to do next
sub do_rename {
  my ($kernel, $heap, $event, $fr, $to) = @_[KERNEL, HEAP, STATE, ARG0, ARG1];

  goto_state("rename");

  $heap->{complex_stack} = [ "RNTO", $to ];
  command( [ "RNFR", $fr ] );
  return;
}

# successful RNFR
sub handler_rename_intermediate {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line = substr($input, 4);

  send_event( "rename_partial",
	      $status, $line,
	      $heap->{event}->[1] );

  command( $heap->{complex_stack} );
  return;
}

# successful RNTO
sub handler_rename_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line = substr($input, 4);

  send_event( "rename",
	      $status, $line,
	      $heap->{event}->[1] );

  delete $heap->{complex_stack};
  goto_state("ready");
  return;
}

# failed RNFR or RNTO
sub handler_rename_failure {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line   = substr($input, 4);

  send_event( "rename_error",
	      $status, $line,
	      $heap->{event}->[1] );

  delete $heap->{complex_stack};
  goto_state("ready");
  return;
}

# initiate a STOR command
sub do_put {
  my ($kernel, $heap, $event) = @_[KERNEL, HEAP, STATE];

  goto_state("put");

  $heap->{complex_stack} = { command => [$event, @_[ARG0..$#_]],
			     sendq   => [],
			   };

  establish_data_conn();
  return;
}

# socket flushed, see if socket can be closed
sub handler_put_flushed {
  my ($kernel, $heap, $session) = @_[KERNEL, HEAP];

  warn "data flushed " . $heap->{complex_stack}->{last_length} if DEBUG;

  # if no packet was pending, this was simply to get things going or to
  # check for suicide and thus will confuse the user if sent
  if ($heap->{complex_stack}->{pending}) {
    $heap->{complex_stack}->{pending} = 0;

    send_event( "put_flushed",
		$heap->{complex_stack}->{last_length},
		$heap->{complex_stack}->{command}->[1] )
      if $heap->{complex_stack}->{last_length};
  }

  warn "Q||: " . scalar @{$heap->{complex_stack}->{sendq}} if DEBUG;

  # we use an internal sendq and send lines as each line is sent
  # this way we can give the user feedback as to the status of the upload
  # so, whenever data is flushed send the next packet
  if ( defined(my $line = shift @{$heap->{complex_stack}->{sendq}}) ) {
    warn "sending queued packet: " . length ($line) if DEBUG;

    $heap->{complex_stack}->{pending} = 1;
    $heap->{data_rw_wheel}->put($line);
    $heap->{complex_stack}->{last_length} = length $line;
  }
  elsif ($heap->{data_suicidal}) {
    warn "killing suicidal socket" . $heap->{data_rw_wheel}->get_driver_out_octets() if DEBUG;

    clean_up_complex_cmd();
    $heap->{data_suicidal} = 0;

    send_event("put_closed",
	       $heap->{complex_stack}->{command}->[1]);
    goto_state("ready");
  }
  return;
}

# remote end closed data connection
# in put this in an error, not a normal condition
sub handler_put_data_error {
  my ($kernel, $heap, $error) = @_[KERNEL, HEAP, ARG0];

  send_event( "put_error", $error,
	      $heap->{complex_stack}->{command}->[1] );

  clean_up_complex_cmd();
  goto_state("ready");
  return;
}

# client sending data for us to print to the STOR
sub do_put_data {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
  warn "put: " . length($input) if DEBUG;

  # add to send queue

  $kernel->call('cmd_connected', @{$heap->{cmd_sock_wheel}}[0]);
  push @{ $heap->{complex_stack}->{sendq} }, $input;

  # send the first flushed event if this was the first item
  unless ( @{ $heap->{complex_stack}->{sendq} } > 1
	   or $heap->{complex_stack}->{pending} ) {
    $kernel->yield('data_flush');
  }
  return;
}

# client request to end STOR command
sub do_put_close {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  warn "setting suicidal on" if DEBUG;

  $heap->{data_suicidal} = 1;

  # if close is called when sendq is empty, we'll need to fake a flush
  unless ( @{ $heap->{complex_stack}->{sendq} } > 0
	   or $heap->{complex_stack}->{pending} ) {
    warn "empty sendq, manually flushing" if DEBUG;
    $kernel->yield('data_flush');
  }
  return;
}

## login state

# connection established, create a rw wheel
sub handler_init_connected {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    # clear the timeout
    $kernel->delay("timeout");

    $heap->{cmd_rw_wheel} = POE::Wheel::ReadWrite->new(
	Handle     => $socket,
        Filter     => POE::Filter::Line->new( Literal => EOL ),
        Driver       => POE::Driver::SysRW->new(),
        InputEvent => 'cmd_input',
        ErrorEvent => 'cmd_error'
    );
  return;
}

# connect to server failed, clean up
sub handler_init_error {
    my ($kernel, $heap, $errnum, $errstr) = @_[KERNEL, HEAP, ARG1, ARG2];

    # clear the timeout
    $kernel->delay("timeout");

    delete $heap->{cmd_sock_wheel};
    send_event( "connect_error", $errnum, $errstr );
  return;
}

# wheel established, log in if we can
sub handler_init_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line = substr($input, 4);

  send_event( "connected",
	      $status, $line );


  if ($heap->{tlscmd}) {
    goto_state("authtls");
    $kernel->yield("authtls");
  }
  else {
    goto_state("login");

    if ( defined $heap->{user} and defined $heap->{pass} ) {
      $kernel->yield("login");
    }
  }
  return;
}

# start the tls negotiation on the control connection by sending "AUTH TLS"
sub do_send_authtls {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    command( [ 'AUTH', 'TLS'] );
  return;
}

sub handler_authtls_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $socket = $heap->{cmd_rw_wheel}->get_input_handle();
  delete $heap->{cmd_rw_wheel};

  eval { $socket = Client_SSLify( $socket, 'tlsv1' )};
  if ( $@ ) {
    die "Unable to SSLify control connection: $@";
  }

  # set up the rw wheel again

  $heap->{cmd_rw_wheel} = POE::Wheel::ReadWrite->new(
      Handle     => $socket,
      Filter     => POE::Filter::Line->new( Literal => EOL ),
      Driver     => POE::Driver::SysRW->new(),
      InputEvent => 'cmd_input',
      ErrorEvent => 'cmd_error'
  );

  goto_state("login");
  $kernel->yield("login");
  return;
}

sub handler_authtls_failure {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line   = substr($input, 4);

  send_event( "login_error",
              $status, $line );
  return;
}

# login using parameters specified during spawn or passed in now
sub do_login_send_username {
  my ($kernel, $heap, $user, $pass) = @_[KERNEL, HEAP, ARG0 .. ARG1];

  $heap->{user} = $user unless defined $heap->{user};
  croak "No username defined in login" unless defined $heap->{user};
  $heap->{pass} = $pass unless defined $heap->{pass};
  croak "No password defined in login" unless defined $heap->{pass};

  command( [ 'USER', $heap->{user} ] );
  delete $heap->{user};
  return;
}

# username accepted
sub do_login_send_password {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  command( [ 'PASS', $heap->{pass} ] );
  delete $heap->{pass};
  return;
}

sub handler_login_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line = substr($input, 4);

  if ($heap->{tlsdata}) {
    goto_state("pbsz_prot");
    $kernel->yield('pbsz');
  }
  else {
    send_event( "authenticated",
              $status, $line );

    goto_state("ready");
  }
  return;
}

sub handler_login_failure {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line = substr($input, 4);

  send_event( "login_error",
	      $status, $line );
  return;
}


# PBSZ 0 and PROT P are needed to encrypt the data connection (specified with TLSData)
# this is done _before_ 'authenticated' is sent to the user session (even though the u/p is already accepted)

sub do_send_pbsz {#
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    command( [ 'PBSZ', '0' ] );
  return;
}

sub do_send_prot {#
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    command( [ 'PROT', 'P' ] );
  return;
}


sub handler_pbsz_prot_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  if ($heap->{event}->[0] eq "PBSZ") {
    $kernel->yield("prot");
  }
  else {
    my $status = substr($input, 0, 3);
    my $line = substr($input, 4);

    send_event( "authenticated", $status, $line );
    goto_state("ready");
  }
  return;
}

sub handler_pbsz_prot_failure {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line   = substr($input, 4);

  send_event( "login_error",
              $status, $line );
  return;
}

## default_simple state

# simple commands simply involve a command and one or more responses
sub do_simple_command {
  my ($kernel, $heap, $event) = @_[KERNEL, HEAP, STATE];

  goto_state("default_simple");

  command( [ $event, @_[ARG0..$#_] ] );
  return;
}

# end of response section will be marked by "\d{3} " whereas multipart
# messages will be "\d{3}-"
sub handler_simple_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);

  send_event( lc $heap->{event}->[0],
	      $status, $heap->{ftp_message},
	      $heap->{event}->[1] );

  goto_state("ready");
  return;
}

# server response for failure
sub handler_simple_failure {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line = substr($input, 4);

  send_event( lc $heap->{event}->[0] . "_error",
	      $status, $line,
	      $heap->{event}->[1] );

  goto_state("ready");
  return;
}

## default_complex state

# complex commands are those which require a data connection
sub do_complex_command {
  my ($kernel, $heap, $event) = @_[KERNEL, HEAP, STATE];

  goto_state("default_complex");

  $heap->{complex_stack} = { command => [ $event, @_[ARG0..$#_] ] };

  establish_data_conn();
  return;
}

# use the server response only for data connection establishment
# we will know when the command is actually done when the server
# terminates the data connection
sub handler_complex_success {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
  if ($heap->{event}->[0] eq "PASV") {

    my (@ip, @port);
    (@ip[0..3], @port[0..1]) = $input =~ /(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)/;
    my $ip = join '.', @ip;
    my $port = $port[0]*256 + $port[1];

    $heap->{data_sock_wheel} = POE::Wheel::SocketFactory->new(
      SocketDomain   => AF_INET,
      SocketType     => SOCK_STREAM,
      SocketProtocol => 'tcp',
      RemotePort     => $port,
      RemoteAddress  => $ip,
      SuccessEvent   => 'data_connected',
      FailureEvent   => 'data_connect_error'
    );
  }
  elsif ($heap->{event}->[0] =~ /^PORT/) {
    command($heap->{complex_stack}->{command});
  }
  else {
    goto_state("ready");
  }
  return;
}

# server response for failure
sub handler_complex_failure {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

  my $status = substr($input, 0, 3);
  my $line   = substr($input, 4);

  send_event( $heap->{complex_stack}->{command}->[0] . "_error",
	      $status, $line,
	      $heap->{complex_stack}->{command}->[1] );

  clean_up_complex_cmd();
  goto_state("ready");
  return;
}

# connection announced by server
sub handler_complex_preliminary {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  # this message is pretty worthless since _connected is all that matters
  send_event( $heap->{complex_stack}->{command}->[0] . "_server",
	      $heap->{complex_stack}->{command}->[1] );

  # sslify the data connection
  my $socket = $heap->{data_rw_wheel}->get_input_handle();
  delete $heap->{data_rw_wheel};
  if ( $heap->{tlsdata} ) {
    eval { $socket = Client_SSLify( $socket, 'tlsv1' )};
    die "Unable to SSLify data connection: $@" if $@;
  }

  # set up the rw wheel again

  $heap->{data_rw_wheel} = POE::Wheel::ReadWrite->new(
    Handle       => $socket,
    Filter       => $heap->{filters}->{ $heap->{complex_stack}->{command}->[0] },
    Driver       => POE::Driver::SysRW->new( BlockSize => $heap->{attr_blocksize} ),
    InputEvent   => 'data_input',
    ErrorEvent   => 'data_error',
    FlushedEvent => 'data_flush'
  );

  return;
}

# data connection established
sub handler_complex_connected {
  my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

  $heap->{data_rw_wheel} = POE::Wheel::ReadWrite->new(
    Handle       => $socket,
    Filter       => $heap->{filters}->{ $heap->{complex_stack}->{command}->[0] },
    Driver       => POE::Driver::SysRW->new( BlockSize => $heap->{attr_blocksize} ),
    InputEvent   => 'data_input',
    ErrorEvent   => 'data_error',
    FlushedEvent => 'data_flush'
  );

  send_event( $heap->{complex_stack}->{command}->[0] . "_connected",
	      $heap->{complex_stack}->{command}->[1] );

  if ($heap->{attr_conn_mode} == FTP_PASSIVE) {
    command($heap->{complex_stack}->{command});
  }
  return;
}

# data connection could not be established
sub handler_complex_connect_error {
  my ($kernel, $heap, $error) = @_[KERNEL, HEAP, ARG0];
  send_event( $heap->{complex_stack}->{command}->[0] . "_error", $error,
	      $heap->{complex_stack}->{command}->[1] );

  clean_up_complex_cmd();
  goto_state("ready");
  return;
}

# getting actual data, so send it to the client
sub handler_complex_list_data {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
  warn "<< $input\n" if DEBUG_DATA;

  send_event( $heap->{complex_stack}->{command}->[0] . "_data", $input,
	      $heap->{complex_stack}->{command}->[1] );
  return;
}

# connection was closed, clean up, and wait for a response from the server
sub handler_complex_list_error {
  my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
  warn "error: complex_list: $input" if DEBUG;
  send_event( $heap->{complex_stack}->{command}->[0] . "_done",
	      $heap->{complex_stack}->{command}->[1] );

  clean_up_complex_cmd();
  dequeue_complex_cmd();
  return;
}

## utility functions

# maps all signal names to dispatcher
sub map_all {
  my $map = shift;
  my $coderef = shift;

  my %signals;
  foreach my $state (keys %$map) {
    @signals{ keys %{ $map->{$state} } } = ();
  }
  map { $_ = $coderef } values %signals;

  return \%signals;
}

# enqueues and incoming signal
sub enqueue_event {
  my ($kernel, $heap, $state) = @_[KERNEL, HEAP, STATE];
  warn "|| enqueue $state" if DEBUG;

  push @{$heap->{queue}}, [ @_ ];

}

# dequeue and dispatch next event
# in a more general model, this could dequeue the first event
# that active session knows how to deal with
sub dequeue_event {
  my $heap = $poe_kernel->get_active_session()->get_heap();
  return unless @{$heap->{queue}};

  my $state = $heap->{queue}->[0]->[STATE];
  warn "|| dequeue $state" if DEBUG;

  dispatch( @{ shift @{$heap->{queue}} } );
}

# if active session knows how to handle this event, dispatch it to them
# if not, enqueue the event
sub dispatch {
  my ($kernel, $heap, $state, $input) = @_[KERNEL, HEAP, STATE, ARG0];

  if ($state eq 'cmd_input' && defined $heap->{data_rw_wheel} ) {
      my ($code, $msg) = parse_cmd_string(\$input);
      if ( substr($code, 0, 1) == 2 ) {
        enqueue_complex_cmd(@_);
        return;
      }
  }
  my $coderef = ( $state_map->{ $heap->{state} }->{$state} ||
		  $state_map->{global}->{$state} ||
		  \&enqueue_event );


  warn "-> $heap->{state}\::$state" if DEBUG;
  &{ $coderef }(@_);
  return;
}

# Send events to interested sessions
sub send_event {
    my ( $event, @args ) = @_;
    warn "<*> $event" if DEBUG;

    my $heap = $poe_kernel->get_active_session()->get_heap();

    for my $session ( keys %{$heap->{events}} ) {
        if (
            exists $heap->{events}{$session}{$event} or
            exists $heap->{events}{$session}{all}
        )
        {
            $poe_kernel->post(
                $session,
                ( $heap->{events}{$session}{$event} || $event ),
                @args
            );
        }
    }
  return;
}

# run a command and add its call information to the call stack
sub command {
    my ($cmd_args, $state) = @_;

    $cmd_args = ref($cmd_args) eq "ARRAY" ? [ @$cmd_args ] : $cmd_args;

    my $heap = $poe_kernel->get_active_session()->get_heap();
    return unless defined $heap->{cmd_rw_wheel};

    $cmd_args = [$cmd_args] unless ref( $cmd_args ) eq 'ARRAY';
    my $command = uc shift( @$cmd_args );
    $state = {} unless defined $state;

    unshift @{$heap->{stack}}, [ $command, @$cmd_args ];

    $command = shift( @$cmd_args ) if $command eq "QUOT";

    $command = $command_map{$command} || $command;
    my $cmdstr = join( ' ', $command, @$cmd_args ? @$cmd_args : () );

    warn ">>> $cmdstr\n" if DEBUG_COMMAND;

    $heap->{cmd_rw_wheel}->put($cmdstr);
}

# change active state
sub goto_state {
  my $state = shift;
  warn "--> $state" if DEBUG;

  my $heap = $poe_kernel->get_active_session()->get_heap();
  $heap->{state} = $state;

  my $coderef = $state_map->{$state}->{_start};
  &{$coderef} if $coderef;

}

# initiate start of data connection
sub establish_data_conn {
  my $heap = $poe_kernel->get_active_session()->get_heap();

  if ($heap->{attr_conn_mode} == FTP_PASSIVE) {
    command("PASV");
  }
  else {
    $heap->{data_sock_wheel} = POE::Wheel::SocketFactory->new(
      SocketDomain   => AF_INET,
      SocketType     => SOCK_STREAM,
      SocketProtocol => 'tcp',
      BindAddress    => $heap->{local_addr},
      BindPort       => $heap->{local_port},
      SuccessEvent   => 'data_connected',
      FailureEvent   => 'data_connect_error'
    );
    my $socket = $heap->{data_sock_wheel}->getsockname();
    my ($port, $addr) = sockaddr_in($socket);
    $addr = inet_ntoa($addr);
    $addr = "127.0.0.1" if $addr eq "0.0.0.0";

    my @addr = split /\./, $addr;
    my @port = (int($port / 256), $port % 256);
    command("PORT " . join ",", @addr, @port);
  }
  return;
}

sub parse_cmd_string {
  my $string = shift;
  $$string =~ s/^(\d\d\d)(.?)//o;
  my ($code, $more) = ($1, $2);
  return ($code, $more);
}

sub clean_up_complex_cmd {
  my $heap = $poe_kernel->get_active_session()->get_heap();
  delete $heap->{data_sock_wheel};
  delete $heap->{data_rw_wheel};
  $heap->{complex_stack} = {};
}

sub enqueue_complex_cmd {
  my $heap = $poe_kernel->get_active_session()->get_heap();
  warn "enqueue_complex_cmd $_[STATE]" if DEBUG;
  $heap->{pending_complex_cmd} = \@_;
}

sub dequeue_complex_cmd {
  my $heap = $poe_kernel->get_active_session()->get_heap();
  return unless $heap->{pending_complex_cmd};

  my $state = $heap->{pending_complex_cmd}->[STATE];
  warn "dequeue_complex_cmd $state" if DEBUG;
  my @event = @{ $heap->{pending_complex_cmd} };
  $heap->{pending_complex_cmd} = undef;
  dispatch( @event );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Client::FTP - Implements an FTP client POE Component

=head1 VERSION

version 0.24

=head1 SYNOPSIS

  use POE::Component::Client::FTP;

  POE::Component::Client::FTP->spawn (
     Alias      => 'ftp',
     Username   => 'test',
     Password   => 'test',
     RemoteAddr => 'localhost',
     Events     => [ qw( authenticated put_connected put_error put_closed
                       get_connected get_data get_done size ) ]
  );

  # we are authenticated
  sub authenticated {
     $poe_kernel->post('ftp', 'command', 'args');
  }

  # data connection is ready for data
  sub put_connected {
     my ($status, $line, $param) = @_[ARG0..ARG3];

     open FILE, "/etc/passwd" or die $!;
     $poe_kernel->post('ftp', 'put_data', $_) while (<FILE>);
     close FILE;
     $poe_kernel->post('ftp', 'put_close');
  }

  # something bad happened
  sub put_error {
     my ($error, $param) = @_[ARG0,ARG1];

     warn "ERROR: '$error' occured while trying to STOR '$param'";
  }

  # data connection closed
  sub put_closed {
     my ($param) = @_[ARG0];
  }

  # file on the way...
  sub get_connected {
     my ($filename) = @_[ARG0];
  }

  # getting data from the file...
  sub get_data {
     my ($data, $filename) = @_[ARG0,ARG1];

  }

  # and its done
  sub get_done {
     my ($filename) = @_[ARG0];
  }

  # response to a size command
  sub size {
     my ($code, $size, $filename) = @_[ARG0,ARG1,ARG2];

     print "$filename was $size";
  }

  $poe_kernel->run();

Latest version and samples script can be found at:
L<http://www.wush.net/poe/ftp>

=head1 DESCRIPTION

POE::Component::Client::FTP is a L<POE> component that implements an non-blocking FTP client.
One C<spawns> an FTP poco from within one's own POE session, asking to receive particular events.

=for Pod::Coverage        DEBUG
       DEBUG_COMMAND
       DEBUG_DATA
       EOL
       FTP_ACTIVE
       FTP_ASCII
       FTP_BINARY
       FTP_MANUAL
       FTP_PASSIVE
       clean_up_complex_cmd
       command
       dequeue_complex_cmd
       dequeue_event
       dispatch
       do_complex_command
       do_init_start
       do_login_send_password
       do_login_send_username
       do_put
       do_put_close
       do_put_data
       do_rename
       do_send_authtls
       do_send_pbsz
       do_send_prot
       do_set_attribute
       do_simple_command
       do_stop
       enqueue_complex_cmd
       enqueue_event
       establish_data_conn
       goto_state
       handler_authtls_failure
       handler_authtls_success
       handler_cmd_error
       handler_cmd_input
       handler_complex_connect_error
       handler_complex_connected
       handler_complex_failure
       handler_complex_flushed
       handler_complex_list_data
       handler_complex_list_error
       handler_complex_preliminary
       handler_complex_success
       handler_init_connected
       handler_init_error
       handler_init_success
       handler_login_failure
       handler_login_success
       handler_pbsz_prot_failure
       handler_pbsz_prot_success
       handler_put_data_error
       handler_put_flushed
       handler_rename_failure
       handler_rename_intermediate
       handler_rename_success
       handler_simple_failure
       handler_simple_success
       map_all
       parse_cmd_string
       send_event

=head1 CONSTRUCTOR

=over

=item spawn

Creates a new POE::Component::Client::FTP session. Takes a number of named parameters:

  Alias          - session name

  Username       - account username

  Password       - account password

  ConnectionMode - FTP_PASSIVE (default) or FTP_ACTIVE  

  Transfermode   - FTP_MANUAL (default), FTP_ASCII, or FTP_BINARY
                   If set to FTP_ASCII OR FTP_BINARY, will use specified
                   before every file transfer.  If not set, you are
                   responsible to manually post the mode.
                   NOTE: THIS IS UNIMPLEMENTED AT THE TIME

  Filters        - a hashref matching signals with POE::Filter's
                   If unspecified, reasonable selections will be made.
                   Only filter currently useful is for ls, which parses
                   common ls responses.  See samples/list.pl for example.

  LocalAddr      - interface to listen on in active mode

  LocalPort      - port to listen on in active mode

  RemoteAddr     - ftp server

  RemotePort     - ftp port

  Timeout        - timeout for connection to server

  BlockSize      - sets the recieve buffer size.  see BUGS

  Events         - events you are interested in receiving.  See OUTPUT.

  TLS	     - Set to true for TLS supporting servers.

  TLSData	     - Set to true for TLS supporting servers of data connections.

TLS support requires the L<POE::Component::SSLify> module to be installed.

=back

=head1 INPUT EVENTS

These are commands which the poco will accept events for:

=over

=item C<cd [path]>

=item C<cdup>

=item C<delete [filename]>

=item C<dir>

=item C<get [filename]>

=item C<ls>

=item C<mdtm [filename]>

=item C<mkdir [dir name]>

=item C<mode [active passive]>

=item C<noop>

=item C<pwd>

=item C<rmdir [dir name]>

=item C<site [command]>

=item C<size [filename]>

=item C<stat [command]>

=item C<syst>

=item C<type [A|I]>

=item C<quit>

=item C<quot [command]>

=item C<put_data>

After receiving a put_connected event you can post put_data events to send
data to the server.

=item C<put_close>

Closes the data connection.  put_closed will be emit when connection is flushed
and closed.

=back

=head1 OUTPUT EVENTS

Output for connect consists of "connected" upon successful connection to
server, and "connect_error" if the connection fails or times out.  Upon
failure, you can post a "connect" message to retry the connection.

Output for login is either "authenticated" if the login was accepted, or
"login_error" if it was rejected.

Output is for "simple" ftp events is simply "event".  Error cases are
"event_error".  ARG0 is the numeric code, ARG1 is the text response,
and ARG2 is the parameter you made the call with.  This is useful since
commands such as size do not remind you of this in the server response.

Output for "complex" or data socket ftp commands is creates "event_connection"
upon socket connection, "event_data" for each item of data, and "event_done"
when all data is done being sent.

Output from put is "put_error" for an error creating a connection or
"put_connected".  If you receive "put_connected" you can post
"put_data" commands to the component to have it write.  A "put_done"
command closes and writes.  Upon completion, a "put_closed" or
"put_error" is posted back to you.

=head1 SEE ALSO

the POE manpage, the perl manpage, the Net::FTP module, RFC 959

=head1 TODO

=over

=item High level functions

High level put and get functions which would accept filenames or
filehandles.  This may simplify creation of an ftp client or batch script.

=item Improve local queueing of send data

=item More sample scripts and documentation

Eventually a graphical ftp client might be interesting.  Please email me
if you decide to attempt this.

=item More complete test cases

=item "Meta" functions

Allow get/put functions to be given filenames or filehandles instead of
requiring the calling script to do standard file io in handlers.

=item Implement TransferMode setting

=back

=head1 BUGS

=over

=item BlockSize

To do the blocksize, I simply rely on the BlockSize parameter in the
Wheel::ReadWrite.  Although it is honored for receiving data, sending data
is done as elements in the array.  Possibly change Driver::SysRW or submit
to the Wheel in proper sizes.  Do not count on receive blocks coming in
proper sizes.

=item TransferMode

FTP_ASCII and FTP_BINARY are not implemented.  Use the 'type' command.

=item Active transfer mode

PORT does not know what ip address it is listening on.  It gets 0.0.0.0.  Use
LocalAddr in the constructor and it all works fine.

=back

Please report any other bugs through C<bug-POE-Component-Client-FTP@rt.cpan.org>

=head1 AUTHOR

Michael Ching <michaelc@wush.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Michael Ching and Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

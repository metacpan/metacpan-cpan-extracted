# Net::MSN - Construct for connecting to the MSN network.
# Originally written by: 
#  Adam Swann - http://www.adamswann.com/library/2002/msn-perl/
# Modified by:
#  David Radunz - http://www.boxen.net/
#
# $Id: MSN.pm,v 1.22 2003/10/29 22:21:48 david Exp $ 

package Net::MSN;

use strict;
use warnings;

BEGIN {
  # Modules
  # CPAN
  use Digest::MD5 qw(md5_hex);

  # Local
  use Net::MSN::PassPort;
  use Net::MSN::SB;

  # Inherit Base Class
  use base 'Net::MSN::Base';

  use constant TRUE  => 1;
  use constant FALSE => 0;
  use constant MSN_PROTOCOL => 'MSNP9 MSNP8 CVRO';
  use constant MSN_VERSION => '6.0.0602';
  use constant OPERATING_SYSTEM => 'winnt 5.1 i386';

  use vars qw($VERSION);

  $VERSION = do { my @r=(q$Revision: 1.22 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r }; 

  use vars qw(%errlist %statuscodes %PendingMsgs);

  %errlist = (
    200 => 'ERR_SYNTAX_ERROR',
    201 => 'ERR_INVALID_PARAMETER',
    205 => 'ERR_INVALID_USER',
    206 => 'ERR_FQDN_MISSING',
    207 => 'ERR_ALREADY_LOGIN',
    208 => 'ERR_INVALID_USERNAME',
    209 => 'ERR_INVALID_FRIENDLY_NAME',
    210 => 'ERR_LIST_FULL',
    215 => 'ERR_ALREADY_THERE',
    216 => 'ERR_NOT_ON_LIST',
    218 => 'ERR_ALREADY_IN_THE_MODE',
    219 => 'ERR_ALREADY_IN_OPPOSITE_LIST',
    280 => 'ERR_SWITCHBOARD_FAILED',
    281 => 'ERR_NOTIFY_XFR_FAILED',
    300 => 'ERR_REQUIRED_FIELDS_MISSING',
    302 => 'ERR_NOT_LOGGED_IN',
    500 => 'ERR_INTERNAL_SERVER',
    501 => 'ERR_DB_SERVER',
    510 => 'ERR_FILE_OPERATION',
    520 => 'ERR_MEMORY_ALLOC',
    600 => 'ERR_SERVER_BUSY',
    601 => 'ERR_SERVER_UNAVAILABLE',
    602 => 'ERR_PEER_NS_DOWN',
    603 => 'ERR_DB_CONNECT',
    604 => 'ERR_SERVER_GOING_DOWN',
    707 => 'ERR_CREATE_CONNECTION',
    711 => 'ERR_BLOCKING_WRITE',
    712 => 'ERR_SESSION_OVERLOAD',
    713 => 'ERR_USER_TOO_ACTIVE',
    714 => 'ERR_TOO_MANY_SESSIONS',
    715 => 'ERR_NOT_EXPECTED',
    717 => 'ERR_BAD_FRIEND_FILE',
    911 => 'ERR_AUTHENTICATION_FAILED',
    913 => 'ERR_NOT_ALLOWED_WHEN_OFFLINE',
    920 => 'ERR_NOT_ACCEPTING_NEW_USERS',
  ); 

  %statuscodes = (
    NLN => 'Online',
    FLN => 'Offline',
    HDN => 'Hidden',
    BSY	=> 'Busy',
    IDL	=> 'Idle',
    BRB	=> 'Be Right Back',
    AWY	=> 'Away',
    PHN => 'On the Phone',
    LUN => 'Out to Lunch'
  );
}

sub new {
  my ($class, %args) = @_;

  my %defaults = (
    ScreenName	       =>	'',
    Handle	       =>	'',
    Password	       =>	'',
    Host	       =>	'messenger.hotmail.com',
    Port	       =>	1863,
    AutoReconnect      =>	1,
    AutoReconnectDelay =>	10,
    _Type	       =>	'NS'
  );
  my $self = __PACKAGE__->SUPER::new(
    __PACKAGE__->SUPER::merge_opts(\%defaults, \%args)
  );

  $self->{_args} = \%args;
  $self->{Callback} = {};
  $self->{Requests} = {};
  $self->{Sessions} = {};
  $self->{Buddies} = {};
  $self->{PendingSB} = {};

  $self->{_PassPort} = new Net::MSN::PassPort(%args);

  return $self;
}

sub _construct_args {
  my ($self, %newargs) = @_;

  if (defined $self->{_args} && ref $self->{_args} eq 'HASH') {
    my %args = %{$self->{_args}};  

    foreach my $arg (keys %newargs) {
      $args{$arg} = $newargs{$arg};
    }

    return %args;
  } else {
    return %newargs;
  }
}

sub _connect_SB {
  my ($self, $chandle, $host, $port, $key, $type, $sid, $pc) = @_;

  $port = $port || $self->{Port};
  $type = $type || 'USR';

  if ($self->if_session_exists($chandle)) {
    $self->{_Log}('## HAVE EXISTING SESSION, CLOSING!! ##', 1);
    $self->_disconnect_SB($self->{Sessions}->{$chandle});
  }
 
  my $sb = new Net::MSN::SB( 
    $self->_construct_args(
      _Host	=>	$host,
      _Port	=>	$port,
      Handle	=>	$chandle
    )
  ); 

  $sb->construct_socket();

  if (defined $pc && $pc == 1) {
    $sb->{PendingCall} = 1;
    $sb->{PendingMsgs} = 1 if ($self->have_pending_msgs($chandle)); 
  }

  $self->remove_pending_SB($chandle);
  $self->{Sessions}->{$chandle} = $sb;

  my $send_msg = $self->{Handle}. ' ' . $key;
  $send_msg .= ' '. $sid if ($type eq 'ANS');

  $sb->send($type, $send_msg);
}

sub _disconnect_SB {
  my ($self, $sb) = @_;

  return unless (defined $sb && $sb);

  my $chandle = $sb->{Handle};

  $sb->remove_socket();
  $self->remove_session($chandle);
}

sub get_SB {
  my ($self, $chandle) = @_;

  if ($self->if_session_exists($chandle)) {
    return $self->{Sessions}->{$chandle};
  }
}

sub if_pending_SB {
  my ($self, $chandler) = @_;

  return (defined $chandler && defined $self->{PendingSB} &&
    exists $self->{PendingSB}->{$chandler} &&
    $self->{PendingSB}->{$chandler} == 1);
}

sub remove_pending_SB {
  my ($self, $chandler) = @_;

  if ($self->if_pending_SB($chandler)) {
    delete($self->{PendingSB}->{$chandler});
  }
}

sub if_request_exists {
  my ($self, $trid) = @_;

  return (defined $trid && defined $self->{Requests} &&
    exists $self->{Requests}->{$trid});
}

sub if_request_type_exists {
  my ($self, $trid, $type) = @_;

  return ($self->if_request_exists($trid) &&
    defined $type &&
    exists $self->{Requests}->{$trid}->{Type} &&
    $self->{Requests}->{$trid}->{Type} eq $type);
}

sub remove_request {
  my ($self, $trid) = @_;

  if ($self->if_request_exists($trid)) {
    delete($self->{Requests}->{$trid});
  }
}

sub if_session_exists {
  my ($self, $chandle) = @_;

  return (defined $self->{Sessions} && defined $chandle && 
    exists $self->{Sessions}->{$chandle});
}

sub remove_session {
  my ($self, $chandle) = @_;

  if ($self->if_session_exists($chandle)) {
    delete($self->{Sessions}->{$chandle});
  }
}

sub sendmsg {
  my ($self, $chandle, $message) = @_;

  return unless (defined $chandle && defined $message);

  my $sb = $self->get_SB($chandle);
  if (defined $sb && $sb) {
    if (defined $sb->{PendingMsgs} && $sb->{PendingMsgs} == 1) {
      push(@{$PendingMsgs{$chandle}}, $message);   
      return 1; 
    }
    unless (defined $sb->{Connected} && $sb->{Connected} == 1) {
      push(@{$PendingMsgs{$chandle}}, $message);
      $sb->{PendingMsgs} = 1;
    } else {
      $sb->sendmsg($message);
    }
    return 1;
  } else {
    if ($self->if_pending_SB($chandle)) {
      push(@{$PendingMsgs{$chandle}}, $message);
    } else {
      push(@{$PendingMsgs{$chandle}}, $message);
      $self->{PendingSB}->{$chandle} = 1;
      return $self->call($chandle);
    }
  }

  return;
}

sub have_pending_msgs {
  my ($self, $chandle) = @_;

  return unless (defined $chandle && $chandle &&
    %PendingMsgs && exists $PendingMsgs{$chandle} &&
    ref $PendingMsgs{$chandle} eq 'ARRAY' &&
    @{$PendingMsgs{$chandle}} >= 1);

  return 1;
}

sub call {
  my ($self, $handle) = @_;

  if ($self->is_buddy_online($handle)) {
    $self->send('XFR', 'SB');

    $self->{Requests}->{$__PACKAGE__::TrID}->{Type} = 'XFR';
    $self->{Requests}->{$__PACKAGE__::TrID}->{Call} = 1;
    $self->{Requests}->{$__PACKAGE__::TrID}->{Handle} = $handle;

    return 1;
  }

  return;
}

sub buddyaddfl {
  my ($self, $username, $fname) = @_;

  $self->send('ADD', 'FL '. $username. ' '. $fname);
}

sub buddyaddal {
  my ($self, $username, $fname) = @_;

  $self->send('ADD', 'AL '. $username. ' '. $fname);
}

sub buddyadd {
  my ($self, $username, $fname) = @_;

  return unless (defined $username);
  return if (defined $self->{Buddies}->{$username});

  $self->{Buddies}->{$username}->{Seen} = 0;
  $self->{Buddies}->{$username}->{FName} = $fname;
  $self->{Buddies}->{$username}->{DisplayName} = $self->normalize($fname);
  $self->{Buddies}->{$username}->{DisplayName} =~ s/0$//;

  unless (defined($self->{Buddies}->{$username}->{Status})) {
    $self->{Buddies}->{$username}->{Status} = $statuscodes{'FLN'};
    $self->{Buddies}->{$username}->{StatusCode} = 'FLN';
    $self->{Buddies}->{$username}->{NLNCode} = '';
    $self->{Buddies}->{$username}->{LastChange} = time;
  }

  return 1;
}

sub buddyupdate {
  my ($self, $username, $fname, $status) = @_;

  return unless (defined $username);

  $self->{Buddies}->{$username}->{Seen} = 1;

  if (defined $fname && $fname) {
    $self->{Buddies}->{$username}->{FName} = $fname;
    $self->{Buddies}->{$username}->{DisplayName} =
      $self->normalize($fname);
  }
  if (defined $status && $status) {
    $self->{Buddies}->{$username}->{Status} = $statuscodes{$status};
    if ($status ne 'FLN' && $status ne 'NLN' &&
    $status ne 'HDN') {
      $self->{Buddies}->{$username}->{StatusCode} = 'NLN';
      $self->{Buddies}->{$username}->{NLNCode} = $status;
    } else {
      $self->{Buddies}->{$username}->{StatusCode} = $status;
      $self->{Buddies}->{$username}->{NLNCode} = '';
    }
    $self->{Buddies}->{$username}->{LastChange} = time;
  }
}

sub buddyname {
  my ($self, $username) = @_;

  return unless (defined $username);
  return $self->{Buddies}->{$username}->{DisplayName};
}

sub buddystatus {
  my ($self, $username, $status) = @_;

  return unless (defined $username);
  return $self->{Buddies}->{$username}->{Status};
}

sub is_buddy_offline {
  my ($self, $username) = @_;

  if ($self->if_buddy_exists($username)) {
    if (defined($self->{Buddies}->{$username}->{StatusCode})) {
      return 1 if ($self->{Buddies}->{$username}->{StatusCode} eq 'FLN');
    }
  }

  return;
}

sub is_buddy_online {
  my ($self, $username) = @_;

  if ($self->if_buddy_exists($username)) {
    if (defined $self->{Buddies}->{$username}->{StatusCode}) {
      return 1 if ($self->{Buddies}->{$username}->{StatusCode} eq 'NLN');
    }
  }

  return;
}

sub if_buddy_exists {
  my ($self, $username) = @_;

  return (defined $username && defined $self->{Buddies}->{$username});
}

sub remove_buddy {
  my ($self, $username) = @_;

  if ($self->if_buddy_exists($username)) {
    delete($self->{Buddies}->{$username});
  }
}

sub connect {
  my ($self, $handle, $password, $args) = @_;

  $self->{'Handle'} = $handle if (defined $handle);
  $self->{'Password'} = $password if (defined $password);

  $self->set_options($args) if (defined $args && ref $args eq 'HASH');

  die "MSN->connect(Username,Password, [{ args }])\n"
    unless (defined $self->{'Handle'} && defined $self->{'Password'});

  die "MSN->connect(Username,Password, [{ Host => 'messenger.hotmail.com'".
    ", Port => 1863 }]\n"
      unless (defined $self->{Host} && defined $self->{Port});

  ($self->{_Host}, $self->{_Port}) = ($self->{Host}, $self->{Port});

  # Create the socket and add to the Select object.
  $self->construct_socket();

  $self->send('VER', MSN_PROTOCOL); 

  return 1;
}

sub disconnect {
  my ($self) = @_;

  $self->sendnotrid('OUT');
  $self->disconnect_socket();
}

sub if_callback_exists {
  my ($self, $callback) = @_;

  return (defined $callback && defined $self->{Callback} &&
    defined $self->{Callback}->{$callback} &&
    ref $self->{Callback}->{$callback} eq 'CODE');
}

sub set_event {
  my ($self, %events) = @_;

  return unless (%events);

  foreach my $event (keys %events) {
    $self->{Callback}->{$event} = $events{$event};
  }
}

sub check_event {
  my ($self) = @_;

  if (my @ready = $__PACKAGE__::Select->can_read(0.1)) {
    foreach my $fh (@ready) {
      my $fn = $fh->fileno();
      my $this_self = ${$__PACKAGE__::Socks->{$fn}};

      if (my $line = $fh->getline()) {
	$line =~ s/[\r\n]//g;
	$self->{_Log}('('. $fn. ')RX: '. $line, 3);
	$self->process_event($this_self, $line, $fh);
      } else {
	$self->cleanup_closed_socket($this_self);
	next;
      }
    }
  }

  return 1;
}

sub cleanup_closed_socket {
  my ($self, $this_self) = @_;

  if ($this_self->{_Type} eq 'SB') {
    $self->{_Log}("Switch Board closed the connection", 1);
    $self->_disconnect_SB($this_self);
  } else {
    $self->{_Log}("Notification Server closed the connection", 1);
    $this_self->remove_socket();
    
    # AutoReconnect
    if (defined $self->{AutoReconnect} && 
    $self->{AutoReconnect} == 1 &&
    defined $self->{AutoReconnectDelay} &&
    $self->{AutoReconnectDelay} >= 0) {
      &{$self->{Callback}->{on_disconnect}} 
	if ($self->if_callback_exists('on_disconnect'));
      $self->{_Log}("Auto Reconnecting .. in ". 
	$self->{AutoReconnectDelay}. " seconds", 1);
      sleep $self->{AutoReconnectDelay};
      $self->connect();
    } else {
      if ($self->if_callback_exists('on_disconnect')) {
	&{$self->{Callback}->{on_disconnect}};
      } else {
	die "Notification Server closed the connection, ". 
	  "and no Auto Reconnect specified!\n";
      }
    }
  }	 
}

sub process_event {
  my ($self, $this_self, $line, $fh) = @_; 

  my ($cmd, @data) = split(/ /, $line);

  return unless (defined $cmd && $cmd);

  if ($cmd eq 'VER') {
    $this_self->send('CVR', '0x0409 '. OPERATING_SYSTEM. ' MSNMSGR '. MSN_VERSION. ' MSMSGS '.  $self->{'Handle'});
  } elsif ($cmd eq 'CVR') {
    $this_self->send('USR', 'TWN I '. $self->{'Handle'});
#  } elsif ($cmd eq 'INF') {
#    my $secpkg = $data[1];
#    if ($secpkg eq 'MD5') {
#      $this_self->send('USR', 'MD5 I '. $self->{'Handle'});
#    } else {
#      $self->{_Log}('Unknown security package: '. $secpkg.
#	' requested by the server', 1);
#    }
  } elsif ($cmd eq 'USR') {
    if ($data[1] eq 'TWN' && $data[2] eq 'S') {
      my $key = $self->{_PassPort}->login(
	$self->{'Handle'}, $self->{'Password'}, $data[3]
      );
      die "Couldnt retrieve session key!" unless (defined $key);
      $this_self->send('USR', 'TWN S '. $key);      
    } elsif ($data[1] eq 'OK') {
      if ($this_self->{_Type} eq 'SB') {
	$this_self->{Connected} = 1;
	if (defined $this_self->{PendingCall} && 
	$this_self->{PendingCall} == 1) {
	  $this_self->send('CAL', $this_self->{Handle});
	} 
      } else {
	$self->{'Handle'} = $data[2];
	$self->{'ScreenName'} = $self->normalize($data[3]);
	&{$self->{Callback}->{on_connect}}
	  if ($self->if_callback_exists('on_connect'));
	$this_self->send('CHG', 'NLN');
	$this_self->send('SYN', '0');
      } 
    } else {
      die "Unsupported authentication method: \"", 
	join(" ", @data), "\"\n";
    }
  } elsif ($cmd eq 'XFR') {
    if ($data[1] eq 'NS') {
      $self->cycle_socket(split(/:/, $data[2]));
      $self->send('VER', MSN_PROTOCOL);
    } elsif ($data[1] eq 'SB') {
      if ($self->if_request_type_exists($data[0], 'XFR') &&
      exists $self->{Requests}->{$data[0]}->{Call} &&
      $self->{Requests}->{$data[0]}->{Call} == 1 &&
      exists $self->{Requests}->{$data[0]}->{Handle}) {
	my ($h, undef) = split(/:/, $data[2]);
	$self->_connect_SB($self->{Requests}->{$data[0]}->{Handle}, 
	  $h, undef, $data[4], 'USR', undef, 1);
	$self->remove_request($data[0]);
      } else {
	$self->{_Log}("Huh? Recieved XFR SB request, ".
	  "but there are no pending calls!", 1);
      }
    }
  } elsif ($cmd eq 'CHL') {
    my ($TrID, $key) = @data;
    my $md5 = md5_hex($key, 'Q1P7W2E4J9R8U3S5');
    $this_self->sendraw('QRY', 'msmsgs@msnmsgr.com '. length($md5). 
      "\r\n". $md5);
  } elsif ($cmd eq 'QRY') {
    # we passed the challenge, lets send a ping
    $this_self->sendnotrid('PNG');
  } elsif ($cmd eq 'PNG') {
    # our ping was recieved.
    
  } elsif ($cmd eq 'CHG') {
    # FIXME: Sends a client state change to the server. Echos the
    # success of the client's state change request.
    #
    # MSN is saying our CHG is OK
    return;
  } elsif ($cmd eq 'SYN') {
    # FIXME: Initiates client-server property synchronization.
    #
    # MSN is saying our SYN is OK
    return;
  } elsif ($cmd eq 'JOI') {
    my ($chandle, $friendly) = @data;
    if ($self->if_callback_exists('on_join')) {
      if ($self->if_session_exists($chandle)) {
	&{$self->{Callback}->{on_join}}($this_self, $chandle, $friendly);
      } else {
	$self->{_Log}('#### WHY AM I HERE?! JOI W/OUT session ####', 1);
      }
    }
    if (defined $this_self->{PendingMsgs} && 
    $this_self->{PendingMsgs} == 1 && $self->have_pending_msgs($chandle)) {
      while (my $message = shift @{$PendingMsgs{$chandle}}) {
	$this_self->sendmsg($message);
      }
      $this_self->{PendingMsgs} = 0;
    }
 } elsif ($cmd eq 'BYE') {
    my ($chandle) = @data;
    $self->_disconnect_SB($this_self);

    if ($self->if_callback_exists('on_bye')) {
      &{$self->{Callback}->{on_bye}}($chandle);
    }
  } elsif ($cmd eq 'CAL') {
    if (defined $this_self->{PendingCall} && 
    $this_self->{PendingCall} == 1) {
      $this_self->{PendingCall} = 0;
    }
  } elsif ($cmd eq 'RNG') {
    my ($sid, $addr, undef, $key, $chandle, $cname) = @data;
    my ($h, undef) = split(/:/, $addr);
    $self->_connect_SB($chandle, $h, '', $key, 'ANS', $sid);
  } elsif ($cmd eq 'ANS') {
    my ($response) = @data;

    $this_self->{Connected} = 1;

    if ($self->if_callback_exists('on_answer')) {
      &{$self->{Callback}->{on_answer}}($this_self, @data);
    }
  } elsif ($cmd eq 'MSG') {
    my ($chandle, $friendly, $length) = @data;
    my ($msg, $response) = ();
    $fh->read($msg, $length);
    unless ($msg =~ m{Content-Type: text/x-msmsgscontrol}s) {
      $msg = $self->normalize($self->stripheader($msg));
      $friendly = $self->normalize($friendly);
      if ($this_self->{_Type} eq 'SB') {
	if ($self->if_session_exists($chandle)) {
	  if ($self->if_callback_exists('on_message')) {
	    &{$self->{Callback}->{on_message}}(
	      $this_self, $chandle, $friendly, $msg
	    );
	  }
	} else {
	  $self->{_Log}('#### WHY AM I HERE?! MSG W/out session ####', 1);
	}
      }
    } else {
      #print STDERR "msg sent: ". $msg. "\n";
    }
  } elsif ($cmd eq 'LST') {
    # FIXME : huh??
    return unless ($data[1] eq 'FL');
    $self->buddyadd($data[5], $data[6]);
  } elsif ($cmd eq 'ILN') {
    my (undef, $status, $username, $fname) = @data;
    $self->buddyupdate($username, $fname, $status);
  } elsif ($cmd eq 'NLN') {
    my ($status, $username, $fname) = @data;
    $self->buddyupdate($username, $fname, $status);
  } elsif ($cmd eq 'FLN') {
    my ($username) = @data;
    $self->buddyupdate($username, undef, $cmd);
  } elsif ($cmd =~ /^[0-9]+$/) {
    if (defined $this_self->{PendingCall} &&
    $this_self->{PendingCall} == 1) {
      $self->_disconnect_SB($this_self);
    }
    $self->{_Log}('ERROR: '. $self->converterror($cmd), 1);
  } elsif ($cmd eq 'ADD') {
    my (undef, $type, undef, $chandle, $friendly) = @data;
    if (defined $type && $type eq 'RL' && !$self->if_buddy_exists($chandle)) {
      if ($self->if_callback_exists('auth_add')) {
	if (&{$self->{Callback}->{auth_add}}($chandle, $friendly)) {
	  $self->buddyaddfl($chandle, $chandle);
	  $self->buddyaddal($chandle, $chandle);
	}
      } else {
	$self->buddyaddfl($chandle, $chandle);
	$self->buddyaddal($chandle, $chandle);
      }
    } 
  } elsif ($cmd eq 'REM') {
    my (undef, $type, undef, $chandle, $friendly) = @data;
    if (defined $type && $type eq 'RL') {
      $self->{_Log}($chandle. ' has removed us from their contact list',
	3);
    } elsif (defined $type && $type eq 'FL') {
      # removed user from our contact list, lets removethe buddy
      $self->{_Log}('removing '. $chandle. ' from our contact list', 3);
      $self->remove_buddy($chandle);
    } elsif (defined $type && $type eq 'AL') {
      # FIXME
    }
  } else {
    $self->{_Log}('RECIEVED UNKNOWN: '. $cmd. ' '. @data, 2);
  }

  return 1;
}

sub converterror {
  my ($self, $err) = @_;

  return (defined $errlist{$err}) ?
    $err. ': '. $errlist{$err} : $err;
}

sub normalize {
  my ($self, $in) = @_;

  $in =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

  return $in;
}

sub stripheader {
  my ($self, $msg) = @_;

  $msg =~ s/\r//gs;
  $msg =~ s/^.*?\n\n//s;

  return $msg;
}

return 1;

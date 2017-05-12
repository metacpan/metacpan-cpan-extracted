package Net::AIM::Connection;

#
# $Revision: 1.20 $
# $Author: aryeh $
# $Date: 2002/04/23 13:55:28 $
#

=head1 NAME

Net::AIM::Connection - Interface to an AIM connection

=head1 SYNOPSIS

=head1 DESCRIPTION

This module handles the connection and communications between us and the server.  It parses the incoming data and hands it off to handler methods if they are defined.  It currently supports and follows the TOC protocol and contains methods to send out our information and messages. 

=head1 METHODS

=over 4

=cut

use Net::AIM::Event;
use Socket;
use IO::Select;
use Symbol;
use Carp;
use strict;
use vars (                # with a few exceptions...
          '$AUTOLOAD',    #   - the name of the sub in &AUTOLOAD
          '%autoloaded',  #   - the hash containing names of &AUTOLOAD methods
         );

my %autoloaded = (
   'tocserver'  => undef,
   'tocport'     => undef,
   'authserver'  => undef,
   'authport'     => undef,
   'screenname' => undef,
   'password' => undef,
   'agent' => undef,
   'auto_reconnect' => 0,
   'socket'   => undef,
   'select'   => undef,
   'verbose'  => undef,
   'parent'  => undef,
);

my %num_args = (
   nick => 1,
   eviled => 2,
   disconnect => 1,
   chat_join => 2,
   chat_in => 4,
   chat_update_buddy => -1,
   chat_invite => 4,
   chat_left => 1,
   im_in => 3,
   sign_on => 1,
   goto_url => 2,
   config => 1,
   update_buddy => 6,
   error => 2
);

my %nameSlot = (
   chat_invite => 2,
   im_in => 0,
   eviled => 1,
   chat_in => 1
);

sub AUTOLOAD {
    my $self = @_;  ## can't modify @_ for goto &name
    my $class = ref $self;  ## die here if !ref($self) ?
    my $meth;

    ($meth = $AUTOLOAD) =~ s/^.*:://;  ## strip fully qualified portion

    unless (exists $autoloaded{$meth}) {
        croak "No method called \"$meth\" for $class object.";
    }

    eval <<EOSub;
sub $meth {
    my \$self = shift;

    if (\@_) {
        my \$old = \$self->{"_$meth"};
        \$self->{"_$meth"} = shift;
        return \$old;
    } else {
        return \$self->{"_$meth"};
    }
}
EOSub

    ## no reason to play this game every time
    goto &$meth;
}


=pod

=item Net::AIM::Connection-E<gt>new($hash_ref)

      Net::AIM::Connection-E<gt>new( {
	 Screenname => 'perlaim',
	 Password => 'yaddayadda',
	 TocServer => 'toc.oscar.aol.com',
	 TocPort => 80,
	 AuthServer => 'login.oscar.aol.com',
	 AuthPort => 5159
     }

Creates a new Connection object and tries to connect to the  AIM TOC server.
This method creates and objet and calls connect with all the arguments passed to it.

=cut
sub new {
    my $proto = shift;

    # my $class = ref($proto) || $proto;             # Man, am I confused...
    
    my $self = {                # obvious defaults go here, rest are user-set
		_debug      => $_[0]->{_debug},
		_port       => 9898,
		# Evals are for non-UNIX machines, just to make sure.
		_screenname   => "perlaim",
		_password   => '',
		_agent   => 'Net::aim',
		_ignore     => {},
		_config     => {},
		_handler    => {},
		_verbose    =>  0,
		_outseq     =>  0,
		_inseq      =>  0,
		_chat_rooms =>  {},
		_parent     =>  shift,
		_frag       =>  '',
		_connected  =>  0,
		_maxlinelen =>  1024, 
		_format     => {
		    'default' => "[%f:%t]  %m  <%d>",
		},
	      };
    
    bless $self, $proto;
    # do any necessary initialization here
    $self->connect(@_) if @_;
    
    return $self;
}


=pod

=item $aim_conn-E<gt>new($hash_ref)

   $aim_conn-E<gt>new( {
	 Screenname => 'perlaim',  #required
	 Password => 'ilyegk',  #required
	 TocServer => 'toc.oscar.aol.com',
	 TocPort => 9898,
	 AuthServer => 'login.oscar.aol.com',
	 AutoReconnect => 1,
	 Agent => 'Net::aim mychat', # DONT USE 'AIM'!!!
	 AuthPort => 5159
     } );

Sets up a connection to the AOL TOC server.

=cut
sub connect {
    my $self = shift;
    my ($hostname, $sock);

    if (@_) {
	my (%arg) = @_;

	$self->password($arg{'Password'}) if exists $arg{'Password'};
	$self->tocserver($arg{'TocServer'}) if exists $arg{'TocServer'};
	$self->tocport($arg{'TocPort'}) if exists $arg{'Port'};
	$self->authserver($arg{'AuthServer'}) if exists $arg{'AuthServer'};
	$self->authport($arg{'AuthPort'}) if exists $arg{'AuthPort'};
	$self->screenname($arg{'Screenname'}) if exists $arg{'Screenname'};
	$self->agent($arg{'Agent'}) if exists $arg{'Agent'};
	$self->auto_reconnect($arg{'AutoReconnect'}) if exists $arg{'AutoReconnect'};
    }
    
    # Lots of error-checking claptrap first...
    unless ($self->tocserver) { $self->tocserver( 'toc.oscar.aol.com' ); }
    unless ($self->tocport) { $self->tocport( 9898 ); }
    unless ($self->authserver) { $self->authserver( 'login.oscar.aol.com' ); }
    unless ($self->authport) { $self->authport( 5159 ); }
    unless ($self->agent) { $self->agent( $self->{_agent} ); }
    unless ($self->auto_reconnect) { $self->auto_reconnect(0); }
    unless ($self->screenname) { croak "No password was specified on connect()"; }
    unless ($self->password) { croak "No password was specified on connect()"; }
    
    $sock = Symbol::gensym();
    unless (socket( $sock, PF_INET, SOCK_STREAM, getprotobyname('tcp') )) {
        carp ("Can't create a new socket: $!");
	return;
    }


   if (connect( $sock, sockaddr_in($self->tocport, inet_aton($self->tocserver)) )) {
	$self->socket($sock);
    } else {
	carp (sprintf "Can't connect to %s:%s!", $self->tocserver, $self->tocport);
	$self->error(1);
	return;
    }
    
    $self->{_select} =  new IO::Select($self->{_socket});


    # Now, log in to the server...
    my $msg = "FLAPON\r\n\r\n";
    
    if (!defined(send($self->{_socket}, $msg, 0))) {
	carp "Couldn't send introduction to server: $!";
	$self->error(1);
	$! = "Couldn't send FLAPON introduction to " . $self->server;
	return;
    }
    
    $self->{_connected} = 1;
#    $self->parent->addconn($self);
}

=pod

=item $aim->normalize($data)

This method normalizes $data by killing all but strict alphnumeric
characters.  Typically used for screen_names.

=cut
sub normalize {
   my $self = shift;
   my $data = shift;
	   
   $data =~ s/[^A-Za-z0-9]//g;
   $data =~ tr/A-Z/a-z/;
   return $data;
}

=pod

=item $aim_conn->send_im($screen_name, $message)

This method sends $message to $screen_name.

=cut
sub send_im {
   my $self = shift;
   my $user = shift;
   my $msg = shift;

   $user = $self->normalize($user);
   $msg = $self->encode($msg);

   return $self->send_to_AOL("toc_send_im $user $msg");
}

=pod

=item $aim_conn->set_idle($idle_time)

This method sets our idle time to C<$idle_time>.
If $idle_time is omitted it will be set to 0.

=cut
sub set_idle {
   my $self = shift;
   my $idle = shift || 0;

   return $self->send_to_AOL("toc_set_idle $idle");
}

=pod

=item $aim_conn->add_buddy(@buddies)

This method adds C<@buddies> to our buddy list that is set on the server.

=cut
sub add_buddy {
   my $self = shift;
   my @buddies = @_;
	
   return $self->send_to_AOL("toc_add_buddy " . join(' ', map { $self->normalize($_) } @buddies));
}

=pod

=item $aim_conn->add_permit(@buddies)

This method adds C<@buddies> to our permit list that is set on the server.

=cut
sub add_permit {
   my $self = shift;
   my @buddies = @_;

   return $self->send_to_AOL("toc_add_permit " . join(' ', map { $self->normalize($_) } @buddies));
}

=pod

=item $aim_conn->add_deny(@buddies)

This method adds C<@buddies> to our deny list that is set on the server.

=cut
sub add_deny {
   my $self = shift;
   my @buddies = @_;

   return $self->send_to_AOL("toc_add_deny " . join(' ', map { $self->normalize($_) } @buddies));
}

=pod

=item $aim_conn->remove_buddy(@buddies)

This method removes C<@buddies> from our buddy list that is set on the server.

=cut
sub remove_buddy {
   my $self = shift;
   my @buddies = @_;
	
   return $self->send_to_AOL("toc_remove_buddy " . join(' ', map { $self->normalize($_) } @buddies));
}

=pod

=item $aim_conn->set_away($message)

This method sets our idle time to $idle_time.
If $idle_time is omitted it will be set to 0.

=cut
sub set_away {
   my $self = shift;
   my $msg = shift;

   return $self->send_to_AOL("toc_set_away") unless($msg);

   $msg = $self->encode($msg);
   return $self->send_to_AOL("toc_set_away $msg" );
}

=pod

=item $aim_conn->get_info($screen_name)

Sends an info request to the server for $screen_name. The server should
reply with a URL which will contain the info requested about the user.

=cut
sub get_info {
   my $self = shift;
   my $user = shift;

   $user = $self->normalize($user);
   return $self->send_to_AOL("toc_get_info $user" );
}

=pod

=item $aim_conn->set_info($info)

This method sets your info or profile information to C<$info> on the server.

=cut
sub set_info {
   my $self = shift;
   my $info = shift;

   $info = $self->encode($info);
   return $self->send_to_AOL("toc_set_info $info");
}

=pod

=item $aim_conn->evil($user, $anon)

Warn $screen_name.
$anon: boolean value which will determine whether to warn the user anonymously or normally.  Anonymous warnings are less severe.

=cut
sub evil {
   my $self = shift;
   my $user = shift;
   my $anon = shift;
		
   $user = $self->normalize($user);

   if ($anon) {
      $anon = "anon";
   } else {
      $anon = "norm";
   }

   return $self->send_to_AOL("toc_evil $user $anon" );
}

=pod

=item $aim_conn->send_to_AOL($message)

Send $message to the server.  This is used internally by other functions
to send commands to the server.

   $aim_conn->send_to_AOL('toc_add_buddy perlaim')

=cut
sub send_to_AOL {
   my $self = shift;
   my $msg = shift;

#   my $data = pack "aCnn", ('*', 2, $self->{"_outseq"}++, (length($msg) + 1), $msg, 0);
   $msg .= "\0";

   my $data = pack "aCnna*", '*', 2, $self->{"_outseq"}, length($msg), $msg;

   ### DEBUG DEBUG DEBUG
   if ($self->{_debug}) {
      print STDERR ">>> [$self->{_outseq}] $msg\n";
   }
    
   my $rv = send($self->{_socket}, $data, 0);
   unless ($rv) {
      carp "syswrite: $!";
      return;
   }

   $self->{_outseq}++;
   return $rv;
}

=pod

=item $aim_conn->chat_invite($room, $msg, @buddies)

Invite @buddies to $room with the message $msg

=cut
sub chat_invite {
   my $self = shift;
   my $room = shift;
   my $msg = shift;
   my @buddies = @_;

   $room = $self->normalize($room);
   $msg = $self->encode($msg);
	
   return $self->send_to_AOL("toc_chat_invite $room $msg " . join(' ', map { $self->normalize($_) } @buddies));
}

=pod

=item $aim_conn->chat_accept($room_id)

This will accept an invitation that was sent to us for $room_id

=cut
sub chat_accept {
   my $self = shift;
   my $id = shift;

   return $self->send_to_AOL("toc_chat_accept $id");
}

=pod

=item $aim_conn->chat_leave($room_id)

This method instructs the server to take you out of the room $room_id

=cut
sub chat_leave {
   my $self = shift;
   my $id = shift;

   return $self->send_to_AOL("toc_chat_leave $id" );
}

=pod

=item $aim_conn->chat_whisper($room_id,$user,$msg)

Whisper $msg to $user in the room $room_id

=cut
sub chat_whisper {
   my $self = shift;
   my $room_id = shift;
   my $user = shift;
   my $msg = shift;

   $user = $self->normalize($user);
   $msg = $self->encode($msg);

   return $self->send_to_AOL("toc_chat_whisper $room_id $user $msg" );
}

=pod

=item $aim_conn->chat_send_to_AOL($room_id, $message)

Send $message in chat room $room_id

=cut
sub chat_send {
   my $self = shift;
   my $room = shift;
   my $msg = shift;

   $msg = $self->encode($msg);

   return $self->send_to_AOL("toc_chat_send $room $msg" );
}

=pod

=item $aim_conn->chat_join($roomname)

Send a request to enter the room $roomname

=cut
sub chat_join {
   my $self = shift;
   my $roomname = shift;

#   $roomname = $self->normalize($roomname);
   return $self->send_to_AOL("toc_chat_join 4 $roomname" );
}


# Returns a boolean value based on the state of the object's socket.
=pod

=item $aim_conn->connected()

Returns a boolean value based on the state of the object's socket.

=cut
sub connected {
   my $self = shift;
   return ( $self->{_connected} && $self->socket() );
}

=pod 

=item $aim->debug($debug)

Set whether to print DEBUGGING information to STDERRR.
Accepts $debug which should be a boolean value.

=cut
sub debug {
    my $self = shift;
    if (@_) {
	$self->{_debug} = $_[0];
    }
    return $self->{_debug};
}

#  Any last words?  
#  What would you like on your tombstone?
#
sub DESTROY {
   my $self = shift;
   $self->quit();
}

# Disconnects this Connection object cleanly from the server.
# Takes at least 1 arg:  the format and args parameters to Event->new().
sub disconnect {
   my $self = shift;
    
   $self->{_connected} = 0;
   $self->socket( undef );

}

sub reconnect {
   my $self = shift;
   my $wait = shift || 10;

   sleep($wait);
   $self->connect();
}

# Tells AIM.pm if there was an error opening this connection. It's just
# for sane error passing.
# Takes 1 optional arg:  the new value for $self->{'iserror'}
sub error {
    my $self = shift;

    $self->{'iserror'} = $_[0] if @_;
    return $self->{'iserror'};
}

# Lets the user set or retrieve a format for a message of any sort.
# Takes at least 1 arg:  the event whose format you're inquiring about
#           (optional)   the new format to use for this event
sub format {
    my ($self, $ev) = splice @_, 0, 2;
    
    unless ($ev) {
        croak "Not enough arguments to format()";
    }
    
    if (@_) {
        $self->{'_format'}->{$ev} = $_[0];
    } else {
        return ($self->{'_format'}->{$ev} ||
                $self->{'_format'}->{'default'});
    }
}

# Gets and/or sets the max line length.  The value previous to the sub
# call will be returned.
# Takes 1 (optional) arg: the maximum line length (in bytes)
sub maxlinelen {
    my $self = shift;

    my $ret = $self->{_maxlinelen};
    $self->{_maxlinelen} = shift if @_;
    return $ret;
}

=pod

=item $aim_conn->set_handler($evttype, \&coderef)

Set a sub routine to be called when $event is encountered:
   $aim_conn->set_handler('error', \&on_errror);
   $aim_conn->set_handler('im_in', \&on_im);

=cut
sub set_handler {
   my $self = shift;
   my ($evt, $coderef) = @_;

   $self->{_handler}->{$evt} = $coderef;
}

sub log_in {
   my $self = shift;
   my $data = shift;

   my $screenname = $self->normalize($self->screenname);

   my $seq = int(rand(100000));
   my $signon_data = pack "Nnna".length($screenname), 1, 1, length($screenname), $screenname;
   my $msg = pack "aCnn", '*', 1, $seq, length($signon_data);
   $msg .= $signon_data;

   if (!defined( send $self->{_socket}, $msg, 0 )) {
      carp "syswrite: $!";
      return 0;
   }

   $self->{"_outseq"} = ++$seq;

   $self->send_to_AOL('toc_signon ' . $self->authserver . ' ' .
         $self->authport . ' ' . $screenname . ' ' . 
         $self->encodePass($self->password) .
         ' english ' . $self->encode($self->agent));           

   # For PAUSE
   $self->set_handler('pause', sub { sleep(1); });
   $self->set_handler('disconnect', sub { 
          my $self = shift;
	  my $conn = $self->getconn();
	  $conn->reconnect();
       }) if ($self->auto_reconnect);
   $self->set_handler('sign_on', sub {
      my $self = shift;

      # We should have some buddies here...
      $self->send_buddies();
      $self->set_info('I am running Net::AIM perl module written by Aryeh Goldsmith');
      $self->{_conn}->send_to_AOL('toc_init_done');
      print "Set SIGNON HANDLER\n" if ($self->{_debug});
   });

   print "DONE SIGNON\n" if ($self->{_debug});
}

=pod

=item $aim_conn->encode($str)

This method returns $str encoded as per the TOC specs: escaped special chars ({}[]$) and enclosed in quotes (")

=cut
sub encode {
   my $self = shift;
   my $str = shift;

   $str =~ s/([\\\}\{\(\)\[\]\$\"])/\\$1/g;
   return ('"' . $str . '"');
}

=pod

=item $aim_conn->encodePass($password)

This method roasts $password according to the TOC specs. The roasted password is returned.

=cut
sub encodePass {
   my $self = shift;
   my $password = shift;

   my @table = unpack "c*" , 'Tic/Toc';
   my @pass = unpack "c*", $password;

   my $encpass = '0x';
   foreach my $c (0 .. $#pass) {
            $encpass.= sprintf "%02x", $pass[$c] ^ $table[ ( $c % 7) ];
   }

   return $encpass;
}

=pod

=item $aim_conn->send_config($cfg_str)

Sends $cfg_str to the server to be used as configuration values for the account.

=cut
sub send_config {
   my $self = shift;
   my $configstr = shift;

   $self->send_to_AOL("toc_set_config {$configstr}\n");
   return;

   $configstr = '';

   if ( defined $self->{_config} &&
      exists $self->{_config}->{mode} &&
      $self->{_config}->{mode} =~ /^\d$/ ) {
	 $configstr .= $self->{_config}->{mode};
   } else {
      $configstr .= '1';
   }

   $configstr .= "\n";
   foreach my $group ( keys %{ $self->{_config} } ) {
      next if ($group eq 'mode');  # we did this already
      $configstr .= "g $group\n";
      while (my ($sn, $type) = each %{ $self->{_config}->{$group} } ) {
	 $configstr .= "$type $sn\n";
      }
   }

   $self->send_to_AOL("toc_set_config {$configstr}\n");
#	print "toc_set_config $configstr\n-----\n" ;

}

sub sflap_recv {
   my ($self) = shift;
   my ($marker, $type, $seq, $len, $header, $data);

   print "Entering sflap_recv\n" if ($self->{_debug});

   if (defined recv($self->socket, $header, 6, 0) && length($header) > 0)  {
      ($marker, $type, $seq, $len) = unpack "aCnn", $header;
   } else {	
#      print time . "WE WERE DISCONNETED!!!!\n";
#      print STDERR time . "WE WERE DISCONNETED!!!!\n";
#      $self->disconnect('error', 'Connection reset by peer');
      $self->{_connected} = 0;
      $self->socket( undef );
      return (0, 'DISCONNECT:');
   }
#   my $inseq = ($self->{"_inseq"} + 1) & 0x0000ffff;
#   $seq &= 0x0000ffff;
   $self->{"_inseq"} = $seq;

   unless (defined (recv($self->socket, $data, $len, 0))) {
      return undef;
   }

   $data = unpack("a*", $data);
   if ($self->{_debug}) {
      print STDERR "<<< [$seq] $type $data\n";
   }
   return  ($type, $data);

}

=pod

=item $aim_conn->read_and_parse()

Read a chunk of data off the connection to the server parse it and send it off to any defined handlers.

=cut
sub read_and_parse {
    my ($self) = shift;
    my ($from, $type, $seq, @stuff, $to, $cmd, $ev, $marker,
	$len, $header, $line, $data, $arg);

   print "Entering read_and_parse\n" if ($self->{_debug});

   ($type, $data) = $self->sflap_recv();

   if ($type == 1) {
      $self->log_in($data);
      return;
   }

   return if ($data !~ /\w/);
	
   ($cmd, $arg) = split(/:/, $data, 2);
   $cmd =~ tr/A-Z/a-z/;

   $from = $self->tocserver;
   $to = $self->screenname;

   @stuff = ($arg);
   if (exists $num_args{$cmd}) {
      @stuff = split(/:/, $arg, $num_args{$cmd});

      $from = $stuff[$nameSlot{$cmd}] if (exists $nameSlot{$cmd});
      $to = $stuff[0] if ($cmd eq 'chat_in');
   } else {
   	# We don't know how many args here...
	print STDERR "PARSE: how many args in '$cmd'?\n";
   }

   my $evt = Net::AIM::Event->new(
	 $cmd,
	 $from,
	 $to,
	 @stuff
      );

   # Handle the cmd.
   my $fxn = $self->{_handler}->{$cmd};
#   foreach my $fxn (@{$self->{fxns}->{on_user_list}}) {
      &$fxn($self->parent, $evt, $from, $to) if (defined $fxn);
#   }


}

sub quit {
    my $self = shift;

    # Do any user-defined stuff before leaving
    $self->handler("leaving");

    unless ( $self->connected ) {  return (1)  }
    return 1;
}

"Aryeh Goldsmith <perlaim\@aryeh.net>";
__END__

=pod

=head1 AUTHOR

Aryeh Goldsmith E<lt>perlaim@aryeh.netE<gt>.

=head1 URL

The Net::AIM project:
http://www.aryeh.net/Net-AIM/


The Net::AIM bot list:
http://www.nodoubtyo.com/aimbots/

=head1 SEE ALSO

perl(1)

=cut


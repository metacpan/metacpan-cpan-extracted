package Net::YMSG;

=head1 NAME

Net::YMSG - Interface to the Yahoo! Messenger IM protocol

=head1 SYNOPSIS

	use Net::YMSG;

	my $yahoo = Net::YMSG->new(
		id       => 'your_yahoo_id',
		password => 'your_password',
	);
	$yahoo->login or die "Can't login Yahoo!Messenger";
	$yahoo->send('recipient_yahoo_id', 'Hello World!');

=head1 DESCRIPTION

Net::YMSG is a client class for connecting with the Yahoo! Messenger server, and transmitting and receiving a message.

Since implement of a protocol is the result of analyzing and investigating a packet, it has an inadequate place. However, it is working as expected usually.

=cut

use Carp;
use IO::Socket;
use IO::Select;
use Net::YMSG::Buddy;
use Net::YMSG::CRAM;

use constant YMSG_STD_HEADER => 'YMSG';
use constant YMSG_SEPARATER  => "\xC0\x80";
use constant YMSG_SALT       => '_2S43d5f';

use strict;

use vars qw($VERSION);
$VERSION = '1.2';

=head1 METHODS

This section documents method of the Net::YMSG class.

=head2 Net::YMSG->new()

It should be called with following arguments (items with default value are optional):

	id            => yahoo id
	password      => password
	pre_login_url => url which refers to setting information.
	                 (default http://msg.edit.yahoo.com/config/)
	hostname      => server hostname
	                 (default 'scs.yahoo.com)

Returns a blessed instantiation of Net::YMSG.

Note: If you plan to connect with Yahoo!India (yahoo.co.in), it sets up as follows.

	my $yahoo_japan = Net::YMSG->new(
		pre_login_url => 'http://edit.my.yahoo.co.in/config/',
		hostname      => 'cs.yahoo.co.in',
	);

I<Since it connects with Yahoo!(yahoo.com), this procedure is unnecessary in almost all countries.>

=cut

sub new
{
	my $class = shift;
	my %args = @_;

	bless {
		id       => $args{id},
		password => $args{password},
		hostname => $args{hostname} || 'scs.yahoo.com',
		pre_login_url     => $args{pre_login_url} || 'http://msg.edit.yahoo.com/config/',
		handle   => undef,
		_read    => IO::Select->new,
		_write   => IO::Select->new,
		_error   => IO::Select->new,
		event_handler => undef,
		buddy_list => [],
	}, $class;
}


=head2 $yahoo->id([$yahoo_id])

This method gets or sets the present B<Yahoo Id>.

=cut

sub id
{
	my $self = shift;
	$self->{id} = shift if @_;
	$self->{id};
}


=head2 $yahoo->password([$password])

This method gets or sets the present B<password>.

=cut

sub password
{
	my $self = shift;
	$self->{password} = shift if @_;
	$self->{password};
}


=head2 $yahoo->login()

Call this after C<new()> to logon the Yahoo!Messenger service.

=cut

sub login
{
	my $self = shift;

	my $server = $self->get_connection;
	my $msg = $self->_create_message(
		87, 0,
		'1' => $self->id, 
	);
	$server->send($msg, 0);
	my $event = $self->recv();
#	_dump_packet($event->source);
	my $cram = Net::YMSG::CRAM->new;
	$cram->set_id($self->id);
	$cram->set_password($self->password);
	$cram->set_challenge_string($event->body);
	my ($response_password, $response_crypt) = $cram->get_response_strings();
	my $auth = $self->_create_message(
		84, 0, 
		'0'  => $self->id,
		'6'  => $response_password,
		'96' => $response_crypt,
		'2'  => '1',
		'1'  => $self->id,
	);
	$server->send($auth);
	my $buddy_list = $self->recv();

	my $login = $self->recv();
	my $handler = $self->get_event_handler();
	$handler->accept($login) if $handler;

	$self->add_event_source($server, sub {
		my $event = $self->recv;
		my $handler = $self->get_event_handler;
		$handler->accept($event);
	} ,'r');

	return $login->is_enable();
}


sub _dump_packet
{
	my $source = shift;
	print join ' ', map {
		sprintf '%02x(%s)', ord $_, (/^[\w\-_]$/) ? $_ : '.';
	} split //, $source;
	print "\n";	
}


=head2 $yahoo->send($yahoo_id, $message)

This method send an Instant-Message B<$message> to the user specified by B<$yahoo_id>. 
=cut

sub send
{
	my $self = shift;
	my $recipient = shift;
	my $message = join '', @_;
	my $server = $self->handle;
        my $event = $self->create('SendMessage');
        $event->from($self->id);
        $event->to($recipient);
        $event->body($message);
	$event->option(1515563606);  # in Buddy list then 1515563606 else 1515563605
	$server->send($event->to_raw_string, 0);
}

=head2 $yahoo->chatsend($chatroom, $message)

This method send a Message B<$message> to the given B<$chatroom>.

=cut


sub chatsend
{
	my $self = shift;
	my $login = $self->{id};
	my ($roomname, $message) = @_;
	#my $message = join '', @_;
		
	my $body="1".YMSG_SEPARATER.$login.YMSG_SEPARATER."104".YMSG_SEPARATER.$roomname.YMSG_SEPARATER."117".YMSG_SEPARATER.$message.YMSG_SEPARATER."124".YMSG_SEPARATER."1".YMSG_SEPARATER;
	
	my $header = pack "a4Cx3nnNN",
		YMSG_STD_HEADER,
		9,
		length $body,
		168,
		0,
		$self->identifier || 0;

	my $msg = $header.$body;
	if(! defined $self->identifier) {
	print STDERR "ERROR:Identifier Not Found";
	}
	my $server=$self->get_connection();
	my $num=$server->send($msg,0);
	
      
}


=head2 $yahoo->change_state($busy, $status_message)

This method sets the I<status messages> for the current user. 'Status message' is set by C<$status_message>. 'Busy icon' is set by the numerical value of C<$busy>.

The C<$busy> should be called with following arguments:

	0 - I'm Available
	1 - Busy
	2 - Sleep

=cut

sub change_state
{
	my $self = shift;
	my $busy = shift;
	my $message = join '', @_;
	my $server = $self->handle;

	my $event = $self->create('ChangeState');
	$event->status_code(99);    # 99 : Custom status
	$event->busy($busy);
	$event->body($message);

	$server->send($event->to_raw_string, 0);
}


sub change_status_by_code
{
	my $self = shift;
	my $status_code = shift || 0;
	my $server = $self->handle;

	my $event = $self->create('ChangeState');
	$event->status_code($status_code);
	$event->busy(1);

	$server->send($event->to_raw_string, 0);	
}


sub ping
{
	my $self = shift;
	my $server = $self->get_connection;
	my $command = $self->_create_message(
		76, 0, 0, ''
	);
	$server->send($command, 0);
	my $pong = $self->recv();
	return $pong->is_enable;
}

=head2 $yahoo->recv()

This method reads the message from a server socket and returns a corresponding B<Event object>.
The B<Event object> which will be returned is as follows:

	Net::YMSG::InvalidLogin     - Invalid Login
	Net::YMSG::Login            - Succeeded in Login.
	Net::YMSG::GoesOnline       - Buddy has logged in.
	Net::YMSG::ReceiveMessage   - Message was received.
	Net::YMSG::ChangeState      - Buddy has change status.
	Net::YMSG::GoesOffline      - Buddy logged out.
	Net::YMSG::NewFriendAlert   - New Friend Alert.
    Net::YMSG::ChatRoomLogon    - Log in chat room
    Net::YMSG::ChatRoomReceive- Log in chat room
    Net::YMSG::ChatRoomLogoff    - Log in chat room
	Net::YMSG::UnImplementEvent - Un-implemented event was received.

All event objects have the following attributes:

=over 4

=item $event->from

B<Yahoo id> which invoked the event.

=item $event->to

B<Yahoo id> which should receive an event.

=item $event->body

The contents of an event. The message and state which were transmitted.

=item $event->code

The event number on Yahoo Messenger Protocol.

=back

=cut

sub recv
{
	my $self = shift;
	require Net::YMSG::EventFactory;
	my $event_factory = Net::YMSG::EventFactory->new($self);
	return $event_factory->create_by_raw_data();
}


=head2 $yahoo->get_connection()

This method returns a raw server socket. When connection has already ended, the socket is returned, and when not connecting, it connects newly.

=cut

sub get_connection
{
	my $self = shift;
	return $self->handle if $self->handle;

	my $server = IO::Socket::INET->new(
		PeerAddr => $self->{hostname},
		PeerPort => $self->get_port,
		Proto    => 'tcp',
		Timeout  => 30,
	) or die $!;
	$server->autoflush(1);
	return 	$self->handle($server);
}



sub buddy_list
{
	my $self = shift;
	@{$self->{buddy_list}} = @_ if @_;
	return @{$self->{buddy_list}};
}


sub get_buddy_by_name
{
	my $self = shift;
	my $name = shift;
	my ($buddy) = grep { lc $_->name eq lc $name } $self->buddy_list;
	return $buddy;
}


=head2 $yahoo->set_event_hander($event_handler)

This method sets the Event handler for a specific Yahoo!Messenger server event. C<$event_handler> is the sub class of Net::YMSG::EventHandler.

Note: The event which can be overwritten should look at the method signature of L<Net::YMSG::EventHandler>.

=cut

sub set_event_handler
{
	my $self = shift;
	$self->{event_handler} = shift;
}


sub get_event_handler
{
	my $self = shift;
	return $self->{event_handler};
}


=head2 $yahoo->add_event_source($file_handle, $code_ref, $flag)

This method adds the file handle (event sauce) to supervise. The file handle to add is specified by C<$file_handle>. The code reference to the processing to perform is specified by $code_ref. 

	C<$flag> eq 'r' - set when the file handle to add is an object for read.
	C<$flag> eq 'w' - set when the file handle to add is an object for write.

By adding another handle (for example, STDIN), processing can be performed based on those inputs. Usually, the server socket of 'Yahoo!Messenger server' is set as a candidate for surveillance.

	ex:
		# The input of STDIN is transmitted to 'EXAMPLE_YAHOO_ID'.
		$yahoo->add_event_source(\*STDIN, sub {
			my $message = scalar <STDIN>;
			chomp $message;
			$yahoo->send('EXAMPLE_YAHOO_ID', $message);
		}, 'r');

=cut

sub add_event_source
{
	my $self = shift;
	my ($handle, $code, $flag, $obj) = @_;

	foreach my $mode (split //, lc $flag) {
		if ($mode eq 'r') {
			$self->{_read}->add($handle);
		}
		elsif ($mode eq 'w') {
			$self->{_write}->add($handle);
		}
	}
	$self->{_connhash}->{$handle} = [ $code, $obj ];
}


=head2 $yahoo->start()

If you're writing a fairly simple application that doesn't need to interface with other event-loop-based libraries, you can just call start() to begin communicating with the server.

=cut

sub start
{
	my $self = shift;
	while (1) {
		$self->do_one_loop;
	}
}


sub do_one_loop
{
	my $self = shift;

	for my $ready (IO::Select->select(
		$self->{_read}, $self->{_write}, $self->{_error}, 10
		))
	{
		for my $handle (@$ready) {
			my $event = $self->{_connhash}->{$handle};
			#$event->[0]->($event->[1] ? ($event->[1], $handle) : $handle);
			$event->[0]();
		}
	}
}

sub invisible {
	my $self=shift;
	my $msg = $self->_create_message(03,0,'');
	my $server= $self->get_connection();
	$server->send($msg,0);
	#return $msg;
}
=head2 $yahoo->invisible()

This method makes you B<invisible> to other users..

=cut


sub pre_join {
	my $self = shift;
	my $login = $self->{id};
	#my ($login) = @_;
	#print "recd : $login\n";
	my $body="109".YMSG_SEPARATER.$login.YMSG_SEPARATER."1".YMSG_SEPARATER.$login.YMSG_SEPARATER."6".YMSG_SEPARATER."abcde".YMSG_SEPARATER;
	
	my $header = pack "a4Cx3nnNN",
		YMSG_STD_HEADER,
		9,
		length $body,
		150,
		0,
		$self->identifier || 0;

	my $msg = $header.$body;
	if(! defined $self->identifier) {
	print STDERR "ERROR:Identifier Not Found";
	}
	my $server=$self->get_connection();
	my $num=$server->send($msg,0);
	#print STDERR "Send $num bytes\n";
	return $msg;

}

sub join_room {
	my $self = shift;
	my $login = $self->{id};
	my ($roomname , $roomid)= @_;
	#print "recd : $login $roomname $roomid\n";
#	my $msg = $self->_create_message(98,0,
#	'1'	=>	$login,
#	'104'	=> $roomname,
#	'129'	=> $roomid,
#	'62'	=> "2",
#	);
	
	my $body="1".YMSG_SEPARATER.$login.YMSG_SEPARATER."104".YMSG_SEPARATER.$roomname.YMSG_SEPARATER."129".YMSG_SEPARATER.$roomid.YMSG_SEPARATER."62".YMSG_SEPARATER."2".YMSG_SEPARATER;
	
	my $header = pack "a4Cx3nnNN",
		YMSG_STD_HEADER,
		9,
		length $body,
		152,
		0,
		$self->identifier || 0;

	my $msg = $header.$body;
	if(! defined $self->identifier) {
	print STDERR "ERROR:Identifier Not Found";
	}
	my $server=$self->get_connection();
	my $num=$server->send($msg,0);
	#print STDERR "Send $num bytes\n";
	return $msg;
	}

=head2 $yahoo->join_room($roomname,$roomid)

This method logs you in B<$roomname>. You need to provide the B<$id> along with Roomname.
Check out http://www.cse.iitb.ac.in/varunk/YahooProtocol.php for the list of RoomIDs corresponding
to the Room you wish to join.[This is a comprehensive list and might not list all available rooms
at that moment; Follow instructions to get the roomid of the room you wish to join]

=cut


sub logoffchat {
	my $self=shift;
	my $login=$self->{id};
	my $body="1".YMSG_SEPARATER.$login.YMSG_SEPARATER;
	
	my $header = pack "a4Cx3nnNN",
		YMSG_STD_HEADER,
		9,
		length $body,
		160,
		0,
		$self->identifier || 0;

	my $msg = $header.$body;
	if(! defined $self->identifier) {
	print STDERR "ERROR:Identifier Not Found";
	}
	my $server=$self->get_connection();
	my $num=$server->send($msg,0);
	#print STDERR "Send $num bytes\n";
	return $msg;
}

=head2 $yahoo->logoffchat()

This method logs you off any chat rooms you are currently logged into.

=cut

sub get_port
{
	my $self = shift;
	return $self->{port} if $self->{port};
	return 5050;
}


sub _create_message
{
	my $self = shift;
	my $event_code = shift;
	my $option = shift;
	my %param = @_;

	my $body = join '', map {
		$_. YMSG_SEPARATER. $param{$_}. YMSG_SEPARATER
	} keys %param;

	if ($event_code == 6) {
		my $buddy = $self->get_buddy_by_name($param{5});
		if ($buddy) {
			$option = 1515563606;
		} else {
			$option = 1515563605;
		}
	}
	if ($event_code == 3) {
	$body = "10".YMSG_SEPARATER."12".YMSG_SEPARATER;
	}
	my $header = pack "a4Cx3nnNN",
		YMSG_STD_HEADER,
		9,
		length $body,
		$event_code,
		$option,
		$self->identifier || 0;
	return $header. $body;
}


sub create
{
	my $self = shift;
	my $event_name = shift;

	require Net::YMSG::EventFactory;
	my $event_factory = Net::YMSG::EventFactory->new($self);
	return $event_factory->create_by_name($event_name);
}


sub _create_login_command
{
	my $self = shift;
	my $event = $self->create('Login');
	$event->id($self->id);
	$event->password($self->password);
	$event->from($self->id);
	$event->hide(0);
	return $event->to_raw_string;
}


sub handle
{
	my $self = shift;
	$self->{handle} = shift if @_;
	$self->{handle};
}


sub identifier
{
	my $self = shift;
	$self->{identifier} = shift if @_;
	$self->{identifier};
}


#


#	my @buddy = $self->_get_buddy_list_by_array(
#		$self->_get_list_by_name('BUDDYLIST', $response->content)
#	);
#	$self->buddy_list(@buddy);




sub _get_list_by_name
{
	my $self = shift;
	my $name = shift;
	my $string = shift;

	if ($string =~ /BEGIN $name\r?\n(.*)\r?\nEND $name/s) {
		my @list = split /\r?\n/, $1;
		return @list;
	}
}


sub add_buddy_by_name
{
	my $self = shift;
	my $group = shift;
	my @buddy_name = @_;
	my @buddy_list = $self->buddy_list();
	for my $name (@buddy_name) {
		my $buddy = Net::YMSG::Buddy->new;
		$buddy->name($name);
		push @buddy_list, $buddy;
	}
	$self->buddy_list(@buddy_list);
}


1;
__END__

=head2 Receiving Offline Messages

All offline messages would be displayed on login by declaring the B<Event_handler> of B<ReceiveMessage> as following :

my $first=0;
sub ReceiveMessage
{
	 my $self = shift;
	 my $event = shift;
	 my @from = split("\x80",$event->from);
	 my @body = split("\x80",$event->body);
	 my $i;
	 if($first==0 && $#from >= 1) {
# offline messages 
		  print "Your Offline messages :\n[They have been saved in the file \'offline\' in the current directory]\n";
		  open(OFFLINE,">>offline") || printf "Error opening file offline";
		  for($i=0;$i<=$#from;$i++) {
			   print OFFLINE "[".$from[$i]."]: ".$body[$i]."\n";
		  }
		  close(OFFLINE);
	 }
	 $first=1;
	 for($i=0;$i<=$#from;$i++) {
		  if ($body[$i] ne "") {
			   $body[$i] =~ s{</?(?:font|FACE).+?>}{}g;
			   if( ! defined $nametonum{"$from[$i]"} ) {
					$nametonum{"$from[$i]"} = $count;
					$numtoname{"$count"}=$from[$i];
					$count++;
			   }

			   my $message = sprintf "[%s(%s)] %s \n", $from[$i],$nametonum{"$from[$i]"},$body[$i];
			   print $message;
		  }
	 }

}


=cut


=head1 EXAMPLE

=head2 Send message

	#!perl
	use Net::YMSG;
	use strict;
	
	my $yahoo = Net::YMSG->new;
	$yahoo->id('yahoo_id');
	$yahoo->password('password');
	$yahoo->login or die "Can't login Yahoo!Messenger";
	
	$yahoo->send('recipient_yahoo_id', 'Hello World!');
	__END__

=head2 Change Status message

	#!perl
	use Net::YMSG;
	use strict;
	use constant IN_BUSY => 1;
	
	my $yahoo = Net::YMSG->new(
		id       => 'yahoo_id',
		password => 'password',
	);
	$yahoo->login or die "Can't login Yahoo!Messenger";;
	
	$yahoo->change_state(IN_BUSY, q{I'm very busy now!});
	sleep 5;
	__END__

=head2 Become Invisible

	#!perl
	use Net::YMSG;
	use strict;
	
	my $yahoo = Net::YMSG->new(
		id       => 'yahoo_id',
		password => 'password',
	);
	$yahoo->login or die "Can't login Yahoo!Messenger";;
	
	$yahoo->invisible();
	__END__


=head2 Received message output to STDOUT

	#!perl
	use Net::YMSG;
	use strict;
	
	my $yahoo = Net::YMSG->new(
		id       => 'yahoo_id',
		password => 'password',
	);
	$yahoo->set_event_handler(new ToStdoutEventHandler);
	$yahoo->login or die "Can't login Yahoo!Messenger";
	$yahoo->start;
	
	
	
	package ToStdoutEventHandler;
	use base 'Net::YMSG::EventHandler';
	use strict;
	
	sub ChangeState {}
	sub GoesOffline {}
	sub GoesOnline {}
	sub UnImplementEvent {}
	
	sub ReceiveMessage
	{
		my $self = shift;
		my $event = shift;
		printf "%s: %s\n", $event->from, $event->body;
	}
	__END__

=head2 Connect to Yahoo!Japan Messege server

	#!perl
	use Net::YMSG;
	use strict;
	
	my $yahoo = Net::YMSG->new(
		pre_login_url => 'http://edit.my.yahoo.co.in/config/',
		hostname      => 'cs.yahoo.co.in',
	);
	$yahoo->id('yahoo_id');
	$yahoo->password('password');
	$yahoo->login or die "Can't login Yahoo!Messenger";
	
	$yahoo->send('recipient_yahoo_id', 'Namaste!');
	__END__

=head2 Join Room 1 of Linux, FreeBSD, Solaris 

my $chatroom="Linux, FreeBSD, Solaris:1";
my $chatroomcode="1600326591";
my $message= "Hi Room!";
	#!perl
	use Net::YMSG;
	use strict;
	
	my $yahoo = Net::YMSG->new(
		id       => 'yahoo_id',
		password => 'password',
	);
	$yahoo->login or die "Can't login Yahoo!Messenger";;
# Join chat room C<$chatroom>    
	my $msg = $yahoo->pre_join();	
	my $msg=$yahoo->join_room($chatroom,$chatroomcode);

# Send message to chatroom	
	$yahoo->chatsend($chatroom,$message);

# Log off chatroom

    $yahoo->logoffchat();
	__END__

=cut
=cut
=head1 AUTHOR
  Varun Kacholia <varunk@cse.iitb.ac.in> http://www.cse.iitb.ac.in/varunk/  
  Hiroyuki OYAMA <oyama@crayfish.co.jp>  http://ymca.infoware.ne.jp/
 =cut

=head1 See Also
  C<http://www.cse.iitb.ac.in/varunk/YahooProtocol.php>
=cut

=COPYRIGHT
Copyright (C) 2003 Varun Kacholia and Hiroyuki OYAMA. All rights reserved.
This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please refer to the use agreement of Yahoo! about use of the Yahoo!Messenger service.
=cut 


#
# $Id: Connection.pm,v 0.16 2003/08/07 00:01:59 lawrence Exp lawrence $
#

package Net::Msmgr::Connection;
use strict;
use warnings;
use IO::Socket::INET;
use Digest::MD5;
use Carp;

use Net::Msmgr qw(:debug);
use Net::Msmgr::Command;
use Net::Msmgr::Object;

our @ISA = qw ( Net::Msmgr::Object ); 

=pod

=head1 NAME

Net::Msmgr::Connection

=head1 SYNOPSIS

 use Net::Msmgr::Connection;

 my $session = Net::Msmgr::Sesssion->new(....);
 my $connection = new Net::Msmgr::Connection;

 $connection->nserver( ip-address or hostname );
 $connection->nsport( 1863 );	# default port #
 $connection->name('Descriptive Name'); # used in debugging output
 $connection->session($session);	# associate with a session
 $connection->debug($debugflags);	# lots of options here
 $connection->connect;			# open the connection
    
=head1 DESCRIPTION

Net::Msmgr::Connection is the encapsulation for a connection to an Net::Msmgr
Dispatch Server, Notification Server, or Switchboard Server.  It will
instantiate Event watchers to empty the transmit queue as messages are
sent through it, and dispatch messages as they are received from the
network, calling a list of per-message handlers.

=head1 CONSTRUCTOR

 my $connection = new Net::Msmgr::Connection( ... );

	- or -

 my $connection = Net::Msmgr::Command->new( ... );

 Constructor parameters are:

=over

=item nserver (optional)

The server to connect to.  Defaults to messenger.hotmail.com, which is
the current Dispatch Server.

=item nsport (optional)

The port to connect to.  All transfer messages from the network will
include a port, and you ought to honor them, but they appear to
currently always be 1863, which is the default.

=item name (optional)

A descriptive name.  It will show up from time to time in some
debugging output.  It defaults to 'Dispatch Server', which correlates
to the default IP address.

=item session (mandatory)

Correlates the connection to the Net::Msmgr::Session in which it lives.

=item debug (optional)

See the manpage for Net::Msmgr.pm for the full list of debug flags and their meanings.


=back

=head1 INSTANCE METHODS

=over

=cut

sub _fields
{
    return shift->SUPER::_fields, ( send_queue => undef,
				    send_queue_flag => 0,
				    recv_buffer => '',
				    socket => undef,
				    nserver => 'messenger.hotmail.com',
				    nsport => 1863,
				    open => 0,
				    handlers => undef,
				    name => 'Dispatch Server',
				    _closeflag => 0,
				    session => undef,
				    debug => 256 );
}

=pod

=item $connection->shutdown;

Sends an 'OUT' message to the associated server, and marks the
connection for closure.

=cut

sub shutdown
{
    my $self = shift;
    my $cmd = new Net::Msmgr::Command(cmd => 'OUT',
			       type => Net::Msmgr::Command::Async);
    $cmd->send($self);
    $self->close;
}

=pod

=item $connection->close;

Immediately close this connection.  

=cut

sub close
{
    my $self = shift;

    &{$self->session->disconnect_handler}($self) if $self->session->disconnect_handler;
    $self->{socket}->close;
    
    print STDERR "Connection to $self->{nserver}:$self->{nsport} ($self->{name}) closed\n"
	if $self->{debug} & DEBUG_CLOSE;
    $self->{open} = 0;
    undef $self->{socket};
}

sub send($$)
{
    my $self = shift;
    my $message = shift;

    push @{$self->{send_queue}}, $message;
    $self->{send_queue_flag}++; 	# trigger watcher
    $self->_send_message;
}

sub _deq_command
{
    my $self = shift;
    return unless $self->{recv_buffer} =~ m/\r\n/m;
    my $joy = 1;
    do 
    {
	(my $command, $self->{recv_buffer}) = split("\r\n",$self->{recv_buffer},2);
	
	#
	# Parse NS commands
	#
	
	my ($cmd, @parms) = split(' ',$command);
	my $object = new Net::Msmgr::Command( cmd => $cmd, connection => $self, params => \@parms );
	if ($cmd eq 'MSG')
	{
	    $object->type(Net::Msmgr::Command::Payload);
	    my $have = length($self->{recv_buffer});
	    if ($have < $parms[2] )
	    {			# waiting for more input -- Put The Candle Back
		substr($self->{recv_buffer},0,0,$command . "\r\n");
		undef $object;
		$joy = 0;	# and we're going to have to wait
	    }
	    else
	    {			# dequeue entire message
		$object->body(substr($self->{recv_buffer},0,$parms[2],''));
	    }
	}
	else
	{
	    $object->type(Net::Msmgr::Command::Normal);
	}
	
	#
	# now, with the object, call all the handlers registered for it in order
	#
	
	if ($object)		# might get thrown away
	{
	    print STDERR "<-- " . $object->as_text if $self->debug & DEBUG_COMMAND_RECV;
	    $self->session->dispatch_all($self, $object);
	}
    } while ($joy && $self->{recv_buffer} =~ m/\r\n/m);	# keep going while there is content in the buffer
}

=pod

=item $connection->add_handler( $handler, @classes )

For each message in any of @classes, call the handler associated with $handler.

Message Handlers can be registered for each of the inbound messages.
All message handlers are called with at least one parameter, the
Net::Msmgr::Command object encapsulating the message.  Optionally, you can at
registration time add extra parameters to that list.

Handlers look like 'methodname' which will turn into a
$session->methodname($command); If handler is an array ref, the first
element is a session handler, and the following elements will be
passed as the second through nth parameters to that handler.  A
handler 'nonmethod' exists to allow you to call arbitrary code.

An example:  

  my $code = sub { my ($c,$t) = @_; print STDERR $t , $c->as_text } ; 
  $ns->add_handler( [ 'nonmethod', $code, 'test_handler' ] , 'QNG' );

=cut

sub add_handler($$@)
{
    my $self = shift;
    my $handler = shift;
    my @command_classes = @_;

    $handler = [ $handler ] unless ref($handler) eq 'ARRAY';

    foreach my $cc (@command_classes)
    {
	push @{$self->{handlers}->{$cc}}, $handler;
    }
}

sub _send_message($)
{
    my $self = shift;
    my $sock = $self->{socket};

    unless ($sock && $sock->connected)
    {
	print STDERR "Not connected" if $self->{debug} & DEBUG_CONFUSED;
	return;
    }

    return unless $#{$self->{send_queue}} >= 0;

    my $message = shift @{$self->{send_queue}};
    $sock->syswrite($message);

    print STDERR "$self->{name} >>>$message" if $self->{debug} & DEBUG_PACKET_SEND;

    if ($self->{_closeflag} && ($#{$self->{send_queue}} < 0))
    {
	$self->close;
    }
}

sub _close
{
    my $self = shift;
    my $event = shift;

    # generate pseudo command so session can close things off

    my $command = new Net::Msmgr::Command;
    $command->type(Net::Msmgr::Command::Pseudo);
    $command->cmd('close');
    $self->session->dispatch_all($self, $command);
    
}

sub _recv_message
{
    my $self = shift;
#    my $event = shift;

    my $buf;
    my $socket = $self->{socket};
    if ($socket->connected)
    {
	while (my $count = sysread($socket, $buf, 80))
	{
	    $self->{recv_buffer} .= $buf;
	    print STDERR "$self->{name} <<<$buf" if $self->{debug} & DEBUG_PACKET_RECV;
	}
	$self->_deq_command;
    }
    else
    {
	$self->_close;
    }
}

=pod

=item $connection->connect;

Opens the connection, and sets up the Event watchers.

=cut

sub connect
{
    my $self = shift;

    carp "Somebody has been sleeping in my bead ...  " if $self->{socket};
    carp "And he is still here!" if $self->{socket} && $self->{socket}->connected;

    $self->open(0);

    unless ($self->nserver && $self->nsport)
    {
	carp 'missing server or port';
	return undef;
    }

    print STDERR $self->name . ' connecting to: ' , $self->nserver , ':', $self->nsport ,"\n"
	if $self->debug & DEBUG_OPEN; 

    $self->{socket} = new IO::Socket::INET ( PeerAddr => $self->nserver,
					     PeerPort => $self->nsport,
					     Proto => 'tcp');

    carp 'No socket open' unless $self->{socket};

    return unless $self->{socket};

    $self->open(1) if $self->{socket}->connected;

    print STDERR "$self->{name} connected\n"
	if ($self->{socket}->connected && ($self->debug & DEBUG_OPEN ));
    $self->{socket}->autoflush(1);
    $self->{socket}->blocking(0);

#     if ($self->session->domain eq 'Event')
#     {
# 	$self->{recv_watcher} = Event->io(fd => $self->{socket},
# 					  cb => [ $self, '_recv_message' ],
# 					  poll => 're',
# 					  desc => 'recv_watcher',
# 					  repeat => 1);
#     }
#     elsif ($self->session->domain eq 'Perl::Tk')
#     {
# 	$main::mw->fileevent($self->{socket},
# 			     'readable',
# 			     sub { $self->_recv_message } );
#     }

    return $self;
}

1;

#
# $Log: Connection.pm,v $
# Revision 0.16  2003/08/07 00:01:59  lawrence
# Initial Release
#
#

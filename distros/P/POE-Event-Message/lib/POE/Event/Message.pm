# -*- Perl -*-
#
# File:  POE/Event/Message.pm
# Desc:  A generic messaging protocol - to use as a starting point
# Date:  Mon Oct 10 10:35:59 2005
# Stat:  Prototype, Experimental
# Note:  Fix to remove message length limitation contributed 
#        by Martin Holste, Sun 21 Feb 2010
#
package POE::Event::Message;
use 5.006;
use strict;
use warnings;

our $PACK    = __PACKAGE__;
our $VERSION = '0.11';
### @ISA     = qw( );

# WARN:  Don't use POE or the POE::Kernel classes here. This is a
#        generic messaging class that can also be used outside of
#        the POE environment. Support is included for sending and
#        receiving messages across sockets (such as between a POE-
#        based server process and a non-POE client process), and
#        when sending messages across file handles (as in the case 
#        of a POE-based parent process communicating with a non-POE 
#        child process).
#

### POE::Kernel;                      # Don't use POE here!
use POE::Event::Message::Header;      # Header class wraps attributes
### POE::Event::Message::Body;        # ((not yet created))
use POE::Filter::Reference;           # Perl object filtering
use POE::Driver::SysRW;               # sysread/syswrite driver

my $HeaderClass = "POE::Event::Message::Header";
## $BodyClass   = "POE::Event::Message::Body";  # ((not yet created))
our $Driver     = new POE::Driver::SysRW;
our $Filter     = new POE::Filter::Reference;

#-------------------------------------------------------------------------
# Message Creation (new message and reply message)
# Envelope method to create new message with body data

sub new
{   my($class,$header,$body) = @_;

    # This method allows for the following usage:
    # . Creating a new message
    #     $message = $msgClass->new();
    #     $message = $msgClass->new( undef, $msgBody );  # see 'package' method
    #
    # . Creating a reply to an existing message
    #     $response = $msgClass->new( $message->header() );    # header obj
    #     $response = $msgClass->new( $message           );    # message obj
    #
    if (ref($header) and $header =~ /=HASH/ and $header->can("new") ) {
	my $msg = $header;
	$header = $HeaderClass->new( $msg->header() ),

    } else {
	$header = $HeaderClass->new( $header ),
    }

    return( bless my $self = {
	     header => $header,
	       body => $body,
	    ## body => $BodyClass->new( $body ),    # ((no BodyClass yet))
	}, ref($class)||$class 
    );
}

*envelope = \&package;

sub package
{   my($class,$msgBody) = @_;
    return $class->new("", $msgBody);        # create new message "envelope"
}

#-----------------------------------------------------------------------
# Pass through methods for message header object
# and a method to get/set the message body

sub set    { $_[0]->{header} and $_[0]->{header}->set   ( $_[1], $_[2] ) }
sub get    { $_[0]->{header} and $_[0]->{header}->get   ( $_[1]        ) }
sub del    { $_[0]->{header} and $_[0]->{header}->del   ( $_[1]        ) }
sub param  { $_[0]->{header} and $_[0]->{header}->param ( $_[1], $_[2] ) }
sub setErr { $_[0]->{header} and $_[0]->{header}->setErr( $_[1], $_[2] ) }
sub status { $_[0]->{header} and $_[0]->{header}->status()               }
sub stat   { $_[0]->{header} and $_[0]->{header}->stat()                 }
sub err    { $_[0]->{header} and $_[0]->{header}->err()                  }

sub getMode      { $_[0]->{header} and $_[0]->{header}->mode()           }
sub setMode      { $_[0]->{header} and $_[0]->{header}->mode( $_[1] )    }
sub delRouteBack { $_[0]->{header} and $_[0]->{header}->delRouteBack()   }
sub delRouteTo   { $_[0]->{header} and $_[0]->{header}->delRouteTo()     }

*delete = \&del;
*reset  = \&del;
*inResponseToId = \&r2id;

sub hasRouting   { $_[0]->{header} and $_[0]->{header}->hasRouting()     }
sub hasRouteTo   { $_[0]->{header} and $_[0]->{header}->hasRouteTo()     }
sub hasRouteBack { $_[0]->{header} and $_[0]->{header}->hasRouteBack()   }

*getRouting   = \&hasRouting;
*getRouteTo   = \&hasRouteTo;
*getRouteBack = \&hasRouteBack;

sub nextRouteType     { $_[0]->{header}->nextRouteType()     if $_[0]->{header}}
sub nextRouteIsRemote { $_[0]->{header}->nextRouteIsRemote() if $_[0]->{header}}
sub nextRouteIsLocal  { $_[0]->{header}->nextRouteIsLocal()  if $_[0]->{header}}
sub nextRouteIsPost   { $_[0]->{header}->nextRouteIsPost()   if $_[0]->{header}}
sub nextRouteIsCall   { $_[0]->{header}->nextRouteIsCall()   if $_[0]->{header}}

sub id     { $_[0]->{header}->get('id')  }    # unique message ID
sub r2id   { $_[0]->{header}->get('r2id')}    # orig. unique message ID
sub header { $_[0]->{header} }                                 # get only
sub body   { $_[1] ? $_[0]->{body} = $_[1] : $_[0]->{body} }   # get or set

sub addRouteTo
{   my($self, @args) = @_;
    return undef unless $self->{header};
    return $self->{header}->addRouteTo( @args );
}

sub addRouteBack
{   my($self, @args) = @_;
    return undef unless $self->{header};
    return $self->{header}->addRouteBack( @args );
}

sub addRemoteRouteTo
{   my($self, @args) = @_;
    return undef unless $self->{header};
    return $self->{header}->addRemoteRouteTo( @args );
}

sub addRemoteRouteBack
{   my($self, @args) = @_;
    return undef unless $self->{header};
    return $self->{header}->addRemoteRouteBack( @args );
}

#-----------------------------------------------------------------------
# Message Routing and Auto-Replies
# This is an experimental interface to provide a flexible,
# semi-automatic message routing mechanism. It provides 
# the following features as an alternative to "postbacks"
# and extends the concept somewhat.
#
# . immediate routing via "post"  (queued, asynchronous) - post method
# . immediate routing via "call"  (direct,  synchronous) - call method
#
# . forward routing, delayed      (via "post" or "call)  - addRouteTo
# . return routing,  delayed      (via "post" or "call)  - addRouteBack
# . combinations of these two
#
# . forward routing, delayed remote (via socket "write") -addRemoteRouteTo
# . return  routing, delayed remote (via socket "write") -addRemoteRouteBack
# . combinations of these two
#
# In addition, this allows the "stacking" of both forward and 
# return destinations. This is the basis of the "semi-automatic 
# routing" feature. The "route" method DOES need to be called 
# on a message, but the caller DOESN'T need to know anything 
# about the next destination(s).
#
# Some experimentation and experience will determine whether
# these are useful as designed, or if changes are needed.
# The INTENT is that intermediate destinations can be added
# to interrupt the original routing, TEMPORARIALY redirecting
# a message, while STILL allowing it to return as intended.

#---------------------------------------------
# Direct message routing, via "post" or "call"

sub post { shift->_postOrCall( "post", @_ ) }
sub call { shift->_postOrCall( "call", @_ ) }

sub _postOrCall                                      # For immediate routing
{   my($self, $mode, $session, $event, @args) = @_;

    if (! defined $INC{'POE/Kernel.pm'}) {
	return $self->setErr(-1, "'POE::Kernel' module is not loaded in '_postOrCall' method of '$PACK'");
    }

    $session ||= POE::Kernel->get_active_session()->ID();

    return unless ($session and $event);
    $mode = lc $mode;                            # a mode arg?
    $mode ||= lc $self->getMode();               # use prior setting?
    $mode = "post" unless ($mode eq "call");     # default value!

    # NOTE that this changes the default behavior of POE's post/call.
    # Here, arguments are bundled into list references so the result
    # is "more compatible" with POE's postback/callback mechanism.
    #
    # Here, we ensure that the arguments passed here are sent to the
    # target event handler as a list reference to be received in ARG0.
    # The "$self" var (current message) is sent as the only element in
    # a list reference to be received in ARG1. This allows "$self" to 
    # be "received" as if it was sent by the method where post/call was 
    # invoked. In addition, this maintains a compatible result with 
    # the "addRouteTo()/addRouteBack()" method, below. Clear as mud?
    # This is either a good idea or really cludgy. Time will tell.
    #
    # All message events sent via "post()", "call()" or "route()" will
    # result in ONLY two parameters received by the target event handler.

    # issue one of post/call

    my $argRef;

    if ( ($#args == 0) and (ref($args[0]) eq "ARRAY") ) {
	$argRef = $args[0];
    } else {
	$argRef = [ @args ];
    }

    # FIX: handle 'call' return here as done in sub '_autoRouting'

    if (! POE::Kernel->$mode( $session, $event, $argRef, [ $self ] ) ) {

	my $msg = "Error(1): POE_Kernel->$mode( $session, $event, [ $argRef ], [ $self ] )";

	$self->setErr(-1, "$msg: $! in '$PACK'");
	## warn $msg;
    }

  # warn "DEBUG: Route: POE_Kernel->$mode( $session, $event, @args )\n";

    return;
}

#---------------------------------------------
# Automatic message routing, via "post" or "call"

*autoroute = \&route;
*autoRoute = \&route;

sub route                              # forward, if possible, or reply
{   my($self,@newArgs) = @_;

    # routeTo() until empty, then routeBack()
    # 'post' returns:   1=routed,  0=nowhere to route
    # 'call' returns:   whatever 'called' method returns

    my(@list) = ();

    if ( $self->hasRouteTo() ) {
	(@list) = $self->routeTo( @newArgs );
    } elsif ( $self->hasRouteBack() ) {
	(@list) = $self->routeBack( @newArgs );
    }

    return( @list );
}

#---------------------------------------------
# Forward message routing, via "post" or "call"

*forward = \&routeTo;
*routeto = \&routeTo;

sub routeTo                            # activate "auto-forward", if any
{   my($self,@newArgs) = @_;

    my(@list) = $self->_autoRouting( "delRouteTo", @newArgs );
    return( @list );
}

#---------------------------------------------
# Return message routing, via "post" or "call"

*reply     = \&routeBack;
*routeback = \&routeBack;

sub routeBack                          # activate "auto-reply", if any
{   my($self,@newArgs) = @_;

    my(@list) = $self->_autoRouting( "delRouteBack", @newArgs );
    return( @list );
}

#---------------------------------------------
# Generic message routing method

sub _autoRouting                       # activate "auto-routing," if any
{   my($self,$type,@newArgs) = @_;

    # This "generic" method is intended to be called by
    # either the "routeTo" or "routeBack" method, which
    # in turn might be invoked by the "route" method.

    return undef unless $self->{header};

    #---------------------------------------------------------------
    # Depending on the "$type" collect a "RouteTo" or a "RouteBack"
    # Note: "@origArgs" is now included for 'delRouteTo' type.

    $type = "delRouteBack" unless $type eq "delRouteTo";

    my($host, $port, $mode, $session, $event, @origArgs) = $self->$type();

    ##warn "($host, $port, $mode, $session, $event, @origArgs)\n";

    # Must have something to post/call and somewhere to send it!
    # FIX: differentiate between call when "no routing"
    # and call when "incomplete routing" attributes.
    #
    if (! ($session and $event) ) {
	## warn "DEBUG: session='$session'  event='$event'";
	return;
    }

    #---------------------------------------------------------------
    # FIX: ToDo: complete remote routing via '$host', '$port'
    # using the "write" method, below. First, fix up message such
    # that, upon being received, a "route()" will forward it on.
    #
 ###if ($host or $port) {

    if ($port) {
	$host ||= 'localhost';

	my $socket = $self->createSocket( $host, $port );
	if (! $socket) {
	    my $err = "Error: connection to '${host}:$port' refused in '$PACK'";

	    # FIX: Do we overwrite the original error message here? or not??
	    # YES. This is a better (clearer) message here for the user.
	    #
	  # $self->setErr(-1, $err)  unless $self->status();
	    $self->setErr(-1, $err);

	    return $self;
	}

	my($stat,$err) = $self->write( $socket );
	if ($stat) {
	    $self->setErr( $stat, $err );
	    return $self;
	}

	my $response;

	# With a "call" or "sync" mode we expect an immediate
	# response message from the server. With any other
	# mode, such as "async", only a "successful send"
	# response is generated here--this assumes that if
	# an actual response message will be generated, an
	# appropriate "addRemoteRouteBack" was added earlier.

	if (($mode eq "call") or ($mode eq "sync")) {
	    $response = $self->read( $socket );
	} else {
            # FIX: Should this be handled differently??
	    $response = $self->new( $self );
	    $response->setErr( 0, "message sent successfully" );
        }

	$self->shutdownSocket();

	return $response;
    }

    #---------------------------------------------------------------
    # Determine whether we "post" (asych) or "call" (synch)

    $mode ||= lc $self->mode();                  # use prior setting?
    $mode = "post" unless ($mode eq "call");     # default value!

    #---------------------------------------------------------------
    # If we're going to rely on POE, make sure it's available.

    if (! defined $INC{'POE/Kernel.pm'}) {
	$self->setErr(-1, "'POE::Kernel' module is not loaded in '_autoRouting' method of '$PACK'");
	return undef;
    }

    #---------------------------------------------------------------
    # This now works as does 'post/call', when using 'routeTo'.
    # STRANGE SYNTAX here, but it allows for reasonably compatible
    # syntax (and a plug-compatible result) to POE's "postback" 
    # mechanism.
    #
    # NOTE that "$self" is prepended to the "@args" list here! This
    # allows "$self" (current message) to be "received" as if it was 
    # sent by the method where the 'post/call/postback' was invoked.
    # --- This obviously needs some well documented examples. ---

    my (@args);
    if ($type eq "delRouteTo") {                  # issue a post/call
	# This is kind of funky usage but, at the moment, it 
	# seems to be "the right thing." Feedback is welcome.
	# Currently we PREPEND "$self" (current message) to
	# any "new args" when "route()" method is called.
	#
	# Adding "$self" AFTER the orig args and BEFORE added args 
	# is either really good or really cludgy. Time will tell.
	#
	(@args) = ( [ @origArgs ], [ $self, @newArgs ] );

    } else {                                      # emulate postback
	# Currently, these are the same. Should the above change?
	#
	(@args) = ( [ @origArgs ], [ $self, @newArgs ] );
    }

    my(@list) = POE::Kernel->$mode( $session, $event, @args );

    if (! @list ) {

	if ($!) {
	    my $err = "Error(2): POE_Kernel->$mode( $session, $event, @args )";

	    $self->setErr(-1, "$err: $! in '$PACK'");
	    ## warn $err;
	}
    }

    ## warn "DEBUG: Route: POE_Kernel->$mode( $session, $event, @args )\n";

    # Here we return the same result as the POE::Kernel
    # .  for 'post' return a boolean indicating success
    # .  for 'call' return what the called method returns
    #
    return( @list )  if ($mode eq 'call');
    return 1;
}

#-----------------------------------------------------------------------
# Reading and Writing messages, via POE::Filter::Reference,
# for use with file/socket handles. Note that the "$message"
# argument defaults to "$self" -- this allows for nice clean
# syntax in most situations:     $message->write( $fh );

*send     = \&write;
*recv     = \&read;

sub write
{   my($self,$fh,$message) = @_;

    (defined($fh) and length($fh)) or return (1,"nowhere to write");

    # Support class OR object method
    $message = $self   if ((! $message) and ref($self));
    return (1,"nothing to write") unless $message;

    ## warn "DEBUG: write message='$message'\n";

    my $tmp = delete $self->{_socket_}   if (ref $self);
    ## warn "DEBUG fh='$fh' in 'write()'";

    $Driver->put( $Filter->put( [ $message ] ) );    # queue the message
    $Driver->flush( $fh );                           # send the message

    $! and warn "OUCH: Driver/flush failed: $!";
 ## $!  or warn "OKAY: Driver/flush succeeded";

    $self->{_socket_} = $tmp   if ($tmp and ref $self);
    return(0,"");                                    # return success
}

sub read
{   my($self,$fh) = @_;

    ## warn "DEBUG: fh='$fh' in 'read()'";

    (defined($fh) and length($fh)) or return (1,"nowhere to read");

    my $response = $Driver->get( $fh );              # fetch a reply

    if (! $response) {
	$response = $self->new();
	$response->setErr(-1, "no response from server");
	return $response;
    }

    #-------------------------------------------------------------------
    # Fix to remove message length limitation contributed 
    # by Martin Holste, Sun 21 Feb 2010:
    # Parse expected length from the beginning of the first payload
    unless (ref($response) eq 'ARRAY' and $response->[0] =~ /^(\d+)\0/){
        $response = $self->new();
        $response->setErr(-1, 'Error: Did not receive expected payload length at beginning of payload');
        return $response;
    }   
    my $expected_length = $1 + length($1) + 1;
    my $received = length($response->[0]);
    READ_LOOP: while ($received < $expected_length){
        my $buf = $Driver->get($fh);
        foreach (@$buf){
	    push @$response, $_; 
	    $received += length($_);
        }   
    }
    #-------------------------------------------------------------------
    # filter the reply, or report error at this line:
    ($response) = @{ $Filter->get( $response ) };    my $line = __LINE__;

    if (($response) and ($response =~ /=HASH/) and ($response->can( "body" ))) {
	# response is okay
    } else {
	my $body = $response ||"";
	$response = $self->new();
	$response->body( $body );
	my $err  = "Error: unknown message type in 'read' in '$PACK' at line $line";
	   $err .= "\nmessage = '$body'";
	   $err .= "  (was message too big to send?)"  if (! $body);
	$response->setErr(-1, $err );
    }

    return $response;                                # return the reply
}

sub createSocket
{   my($self,$host,$port) = @_;

    $host ||= 'localhost';
    if (! $port) {
	$self->setErr(-1, "Error: port is undefined in 'socket' in '$PACK'" );
	return undef;

    } elsif (! defined $INC{'IO/Socket.pm'} ) {
	$self->setErr(-1, "'IO::Socket' module is not loaded in 'socket' method of '$PACK'");
	return undef;
    }

    my $socket = IO::Socket::INET->new( 'PeerAddr' => $host,
                                        'PeerPort' => $port,
                                        'Proto'    => 'tcp', );
    if (! $socket) {
	$self->setErr(-1, "Error: IO_Socket_INET failed in '$PACK': $!" );
	return undef;
    }

    $self->{_socket_} = $socket;
    return $socket;
}

sub getOpenSocket
{   my($self) = @_;
    return $self->{_socket_} || undef;
}

sub shutdownSocket
{   my($self, $socket) = @_;

    $socket ||= $self->getOpenSocket();

    $socket->shutdown(2);         # proper socket etiquette:
    $socket->close();             #  a shutdown then a close.

    return;
}

#-----------------------------------------------------------------------
# Somewhat useful for debugging ... replace with a better dumper.

sub dump {
    my($self)= @_;
    my($pack,$file,$line)=caller();
    my $text  = "DEBUG: ($PACK\:\:dump)\n  self='$self'\n";
       $text .= "CALLER $pack at line $line\n  ($file)\n";
    my $value;
    foreach my $param (sort keys %$self) {
	$value = $self->{$param};
	$value = $self->zeroStr( $value, "" );  # handles value of "0"
	$text .= " $param = $value\n";
    }
    $text .= "_" x 25 ."\n";

    if (ref($self->{header})) {
	$text .= "header:\n";
	$text .= $self->{header}->dump("nohead");
    }
    return($text);
}

sub zeroStr
{   my($self,$value,$undef) = @_;
    return $undef unless defined $value;
    return "0"    if (length($value) and ! $value);
    return $value;
}
#_________________________
1; # Required by require()

__END__

=head1 NAME

POE::Event::Message - A generic messaging protocol

=head1 VERSION

This document describes version 0.05, released December, 2005.

=head1 SYNOPSIS

 use POE;
 use POE::Event::Message;

 $MsgClass = "POE::Event::Message";


 # Creating Messages

 $body = <whatever>;              #  body can be almost anything 
 $mesg = $MsgClass->new( undef, $body );

 $mesg = $MsgClass->package( $body );   # alternative to 'new()' 


 # Creating Responses to Messages
 # Note that every message has a unique identifier. For
 # replies, the original 'message identifier' is retained
 # as an 'in response to' identifier.

 $resp = $MsgClass->new( $mesg        );
 $resp = $MsgClass->new( $mesg, $body );

 $resp = $MsgClass->new( $mesg->header()        );
 $resp = $MsgClass->new( $mesg->header(), $body );


 # Accessing Message Components

 $mesg->body( $body );            # replace message body
 $body = $mesg->body();           # get message body
 $head = $mesg->header();         # get message header

 print $mesg->dump();             # useful when debugging
 print $mesg->header()->dump();   # useful when debugging


 # Accessing Header Components

 $mesgID = $mesg->id();           # unique message identifier
 $respID = $mesg->r2id();         # 'In Response To' identifier

 $bool   = $mesg->hasRouting();
 $bool   = $mesg->hasRouteTo();
 $bool   = $mesg->hasRouteBack();

 $routing= $mesg->nextRouteType();      # post, call, remote or ''
 $bool   = $mesg->nextRouteIsRemote();  # 1 if remote    or 0 if not
 $bool   = $mesg->nextRouteIsLocal();   # 1 if post|call or 0 
 $bool   = $mesg->nextRouteIsPost();    # 1 if post      or 0 
 $bool   = $mesg->nextRouteIsCall();    # 1 if call      or 0 


 # Set default 'mode' used with 'route / routeto / routeback'

 $mesg->setMode( "call" );        # original default: "post"

 $mode = $mesg->mode();           # one of 'post' or 'call'


 # Routing Messages Within the POE environment
 # note that '$session' defaults to current session context
 # (and the first parameter ('mode') defaults to 'post'
 # unless the 'setMode()' method was used to change this)

 $mesg->addRouteTo( "post", $session, $to_event, @stateArgs );

 $mesg->addRouteBack( "post", "", 'my_handler', @stateArgs );

 ($resp) = $mesg->route( @routeArgs );


 # Routing Messages Outside the POE environment
 # 'sync' expects some sort of response message 
 # 'asynch' expects only 'delivery status' response

 $mesg->addRemoteRouteTo( $host, $port "sync" );

 $mesg->addRemoteRouteTo( $host, $port "async" );

 ($response) = $mesg->route( @routeArgs );


 # Processing Messages Within the POE environment
 # (brief example of 'object_state' event method)

 sub handle_send_response
 {   my($self, $stateArgs, $routeArgs) = @_[ OBJECT, ARG0, ARG1 ];

     my $message  = $routeArgs->[0];
     my $response = $MsgClass->new( $message, "" );

     return $response->route();
 }


 # Directly Sending and Receiving Messages Outside the POE environment
 # where '$fh' is a file handle, socket or whatever

 $MsgClass->write( $fh, $mesg );
 $mesg->write( $fh );

 $response = $MsgClass->read( $fh );
 $response = $mesg->read( $fh );


=head1 DESCRIPTION

This class is a starting point for creating a generic application
messaging protocol. The intent is for this to be used as a foundation
when building network and/or event-driven applications such as Web 
services.

Features of POE::Event::Message include the following.

=over

=item *

Messages of this class have flexible routing capabilities 
that work both inside and outside POE-based applications. 

=item *

A 'local' message routing mechanism is designed to be 
plug-compatible with POE's existing 'postback' mechanism. 
This is referred to as a 'routeback' mechanism in this class. 

=item *

A 'remote' message routing mechanism can be used by message-based
client scripts, or perhaps as a simple alternative to the 'IKC' 
(Inter Kernel Communication) mechanism.

=item *

Messages are delivered based on the type of the destination. 
A 'local' routing will trigger a POE 'post' or 'call' event, 
while a 'remote' routing invokes a socket connection to a 
particular host and port. 

=item *

In addition, this class has the ability to introduce 
multiple 'forward' and/or 'reverse' routing to multiple
event and/or remote host destinations. This allows for
temporary interruption of normal message flow, without
any of the original participants (events or whatever)
knowing or caring.

=item *

Messages can also be sent through a file handle, such as 
from a non-POE child to a POE-based parent process.

=item *

Messages can contain almost anything including binary data
and complex Perl data structures.

=back

Messages are created using the 'L<new()|"new">' method or the 
L<envelope()|"envelope">' or L<package()|"package">' methods.
A message body can be add during creation or afterward using
the L<body()|"body">' method.

Responses to messages can be created using the same message creation
methods but with the originating message as an added argument.
This way, the unique message identifier on the originating message
is added to the reply as an 'in reply to' identifier. This allows
correlating originating messages with their replies, if necessary.

Message routing is flexible and can be either 'B<local>' or 'B<remote>'.
The 'L<addRouteTo()|"addRouteTo">' and 'L<addRouteBack()|"addRouteBack">' 
methods are used to add 'B<local>' routing to POE-based event services.
This type of routing triggers POE's internal 'post' or 'call' mechanism
for asynchronous or synchronous message delivery.

The 'L<addRemoteRouteTo()|"addRemoteRouteTo">' and 
'L<addRemoteRouteBack()|"addRemoteRouteBack">' methods are used to
add 'B<remote>' routing of messages to services on remote hosts.
This type of routing triggers 'L<read()|"read">' and 'L<write()|"write">'
methods to send and receive messages across network sockets. Remote
delivery can be either synchronous (expecting an immediate response 
message) or asynchronous (where response is only a 'delivery status' of 
either successful or unsuccessful).

Multiple forward and/or reverse routing destinations can be added to a 
given message. Additional local and/or remote routing destinations can 
be added at any time during processing. This is useful, for example, to 
interrupt the original message flow, as none of the original participants 
need be aware of any interruption(s).

When adding a routing destination, a list of 'B<StateArgs>' can be 
included. These will be available to the receiving event method when the 
message is delivered (just like POE's postback/callback StateArgs list).

The 'L<route()|"route">' method is used to actually route messages
to their destinations. When routing messages, a list of 'B<RouteArgs>' 
can be included. These will be available to the receiving event method 
when the message is delivered (just like POE's postback/callback 
AdditionalArgs list). I<Note that the routed message object will be
delivered as the first element of the 'B<RouteArgs>' list reference>.

This class does not explicitly use POE. This allows
'light weight' scripts that run outside the full POE environment to
use this messaging protocol. When POE is not used, only the 'B<remote>'
mechanism is available. This is because the 'post' and 'call' routing 
semantics rely on the POE kernel. 

Note also that 'B<local>' routing destinations using 'post' and 'call' can
be created outside of POE. If, for example, messages are sent via a 'remote 
routing' to a POE-based process, that process can then 'L<route()|"route">' 
messages using 'post' and/or 'call' to the specified event service 
destination(s).

When running outside of the POE environment either explicitly add a 
'remote' routing -or- use the L<routeIsRemote()|"routeIsRemote"> method 
(as shown in the L<Synopsis|"SYNOPSIS"> section, above) to determine if 
the L<route()|"route"> method can be called on a given message object.

=head2 Constructor

=over 4

=item new ( [ Message ] [, Body ] )

=item new ( [ Header ] [, Body ] )

This method instantiates a new message object. Optionally it can be 
used to create a response to an existing message. A message body can 
also be specified during creation and/or added later.

=over 4

=item Message | Header

The optional B<Message> or B<Header> argument, used when creating a 
response to an originating message, is expected to be either the 
originating message or the header object from the originating message. 

Every message has a guaranteed unique message identifier. The response
mechanism is used to include the original message identifier as an
'in response to' identifier. This 'r2id' can then be used, when necessary,
to correlate original messages with any responses received.

=item Body

The optional B<Body> argument, when included, can be simple text. 
The Body can also be any arbitrary Perl data structure. This class 
provides a filtering mechanism that allows messages containing Perl 
data structures to be passed across file handles, including sockets
and parent/child stdio file descriptors.

WARN: Use caution when using messages containing Perl 'CODE references.' 
While, as of version 2.05, the underlying 'Storable' module does now 
support passing CODE refs, this has not been tested here.

=back

=back


=head2 Methods

=over 4

=item envelope ( Body )

=item package ( Body )

This method is included to simplify creating a new message object.
The B<Body> argument is included as the body of the message.

=over 4

=item Body

The required B<Body> argument can be either simple text or a Perl data
structure as explained in the L<new> method, above.

=back


=item call ( [ Session ], Event [, Args ] )

=item post ( [ Session ], Event [, Args ] )

These methods provide direct message routing within a POE application 
and will invoke the corresponding method on the POE Kernel for immediate,
synchronous event dispatch (call) or queued for asynchronous event 
dispatch (post).

=over 4

=item Session

This optional argument is the name of an active POE 'B<session>'.
When omitted, the current POE 'session context' is used.

=item Event

This argument specifies the 'B<Event>' that will be generated.

=item Args

The B<Args> parameter is an optional list that can be included
with either of the POE 'post' or 'call' event generators.

=back


=item addRouteTo ( Mode, [ Session ], Event [, StateArgs ] )

=item addRouteBack ( Mode, [ Session ], Event [, StateArgs ] )

=over 4

These methods add B<local> capabilities to messages of this
class. These add routing entries to the message header that can
then be invoked via the L<route> methods, explained below.

=item Mode

The B<Mode> must be a string equal to one of 'B<post>' or 'B<call>'.
Later, when one of the L<route> methods is used, will then invoke 
either the corresponding method on the POE Kernel for immediate, 
synchronous event dispatch (call) or queued for asynchronous event 
dispatch (post).

=item Session

This optional argument is the name of an active POE 'B<session>'.
When omitted, the current POE 'session context' is used.

=item Event

This argument is the name of an 'B<event>' in an active 
POE 'Session'.

=item StateArgs

The B<StateArgs> parameter is an optional list that can be included
with either of the POE 'post' or 'call' event generators.

=back


=item addRemoteRouteTo ( Host, Port, Mode, [ Session ], Event [, StateArgs ] )

=item addRemoteRouteBack ( Host, Port, Mode, [ Session ], Event [, StateArgs ] )

=over 4

These methods add B<remote> capabilities to messages of this
class. These add routing entries to the message header that can
then be invoked via the L<route> methods, explained below.

=item Host

The remote host to which the message will be routed.

=item Port

The network port on the remote host.

=item Mode

The B<Mode> must be a string equal to one of 'B<sync>' or 'B<asynch>'.
Later, when one of the L<route> methods is used, will then either
expect an immediate response message ('sync') or simply return a
status indicating success or failure of 'B<message delivery>' only,
and not wait for any other response. This is useful when some other 
process, perhaps on another host, will handle the response, if any.

The remaining arguments are identical as the corresponding
L<addRouteTo()|"addRouteTo"> and L<addRouteBack()|"addRouteBack"> 
methods described above.

=back


=item route ( [ RouteArgs ] )

=item routeto ( [ RouteArgs ] )

=item routeback ( [ RouteArgs ] )

These methods add B<auto-routing> capabilities to messages of this
class. These extract routing entries from the message header that are
then used to generate POE events using immediate dispatch (when the
routing entry was created with a B<Mode> of 'B<call>') or queued for
delayed dispatch (when the routing entry was created with a B<Mode> 
of 'B<post>').

The B<route> method will first extract B<routeTo> entries and, when
empty, will extract B<routeBack> entries.

The B<routeto> method will extract only those entries created using the 
B<L<addRouteTo>> method, shown above, while the B<routeback> method will 
extract only those entries created using the B<L<addRouteBack>> method,
also shown above.

If/when the routing list(s) are empty, these methods will silently
do nothing. If this should cause an error, use the B<hasRouting>,
B<hasRouteTo> or B<hasRouteBack> methods to determine when an 
error should be generated.

NOTE: The 'B<local>' routing mechanism is designed to be plug-compatible 
with POE's existing 'B<postback>' mechanism. These methods add the ability 
to introduce multiple forward and/or reverse event destinations and can be 
used to temporarially interrupt normal message routing (and none of the
handlers that expect to process the message will even be aware of 
the interruption).

NOTE: The 'B<remote>' routing mechanism can be used as a simple alternative
to the 'IKC' (Inter Kernel Communication) mechanism.

=over 4

=item RouteArgs

The B<RouteArgs> parameter is an optional list that can be added
when any of the 'route()' methods are invoked. These arguments
are then received by whichever event handler happens to
receive the routed message. I<Note that the message itself is
included as the first argument in the B<RouteArgs> list>. 
See the L<Synopsis|"Synopsis"> section, above, and the
L<Examples|"Examples"> section, below, for usage syntax.

=back


=item send ( FH [, Message ] )

=item write ( FH [, Message ] )

These methods provide the ability to send the message object
through an open file handle. The 'B<FH>' parameter should be
an open file handle and the 'B<Message>' parameter, when used,
is expected to be an object of this class. When the 'B<Message>'
is omitted, the current object is sent through the file handle.

WARN: Use caution when using these methods with messages containing 
Perl 'CODE references.' While the underlying 'Storable' module does
now support passing CODE refs, this has not been tested here.

=over 4

=item FH

An open file handle.

=item Message

A message object of this class. Optional when these methods are
called as object methods on an existing object, and required when 
these methods are called as class methods.

When omitted, B<Message> defaults to the current message object.

=back


=item read ( FH )

=item recv ( FH )

These methods provide the ability to receive a message object
through an open file handle.

WARN: Use caution when using these methods with messages containing 
Perl 'CODE references.' While the underlying 'Storable' module does
now support passing CODE refs, this has not been tested here.


=over 4

=item FH

An open file handle.

=back


=item id ()

This method is used to determine the unique message identifier 
of the current message object.


=item inResponseToId ()

=item r2id ()

For 'response messages' these methods are used to determine the 
message identifier of the original message.

Note: This is why, when creating a response message, it is important to
include an originating message as the first argument to the 'L<new()|"new">' 
method. This way the original message ID can be collected and included 
as the 'B<r2id>'.


=item hasRouting ()

=item hasRouteTo ()

=item hasRouteBack ()

Miscellaneous methods used to determine 'header' state. Each of these
returns the next 'routing' header entry, if any, or an 'undef' value.
The 'routing' entry returned is retained in the message header.


=item nextRouteType ()

=item nextRouteIsRemote ()

=item nextRouteIsLocal ()

=item nextRouteIsPost ()

=item nextRouteIsCall ()

Miscellaneous methods used to determine 'header' state. Each of these,
with the exception of 'B<nextRouteType()'>, returns a boolean value
where 'B<0>' indicates the test is false and 'B<1>' indicates the test
is true.

The 'B<nextRouteType()'> method returns a string value that is one of
'B<remote>', 'B<call>', 'B<post>' or '' (an empty string).


=item status

This method returns the current error status of a message object.
When the status code is non-zero, the error message will contain
text of the corresponding error.

=item dump

This method is included for convenience when developing or debugging
applications that use this class. This does not produce a 'pretty'
output, but is formatted to show the contents of the message object
and the message header object, when one exists.

=back

=head1 EXAMPLES

The following is an incomplete example of creating a network interface 
that accepts message objects from a client script and returns message 
responses. 

For a complete working example of this see the 'TCP' and 'Cmd' server 
classes in the 'B<POE-Component-GCS>' distribution available on CPAN.

 package POE::Component::GCS::Server::TCP;

 $ServerAlias = "MsgServer";
 $ServerPort  = 12345;

 sub spawn
 {   my($self) = @_;

     POE::Component::Server::TCP->new(
         Port     => $ServerPort,    # Bind Port
         Alias    => $ServerAlias,   # necessary for 'routeback' response

         ClientInput   => \&handle_msg_input,
         ClientFilter  => "POE::Filter::Reference",

         # Most of the events we need are pre-defined by POE.
         # Add one here to so we can create a "routeback"
         # event target to simplify the response mechanism.

         InlineStates => {
              client_msg_output => \&handle_msg_output,
         },
     );
     return;
 } 

 sub handle_msg_input
 {   my($kernel, $heap, $session, $input) = @_[KERNEL, HEAP, SESSION, ARG0];

     # The $input variable here is expected to be a "$MsgClass" object.
     # Create a msg routeback wormhole using "post" for asynch delivery.

     $input->addRouteBack( post => undef, "client_msg_output", undef );

     # Then "dispatch" the message to some command processor

     $CmdClass->dispatch( $input );        # (non-POE method)
     return;
 }

 sub handle_msg_output                # 'client_msg_output' event handler
 {   my($kernel, $heap, $session, $state_args, $result_args) =
     @_[ KERNEL,  HEAP,  SESSION,  ARG0,        ARG1       ];

     # This handler is the "routeback" target that returns data
     # to client ($reply is expected to be a "$MsgClass" object).
     # Here we simply return it to the waiting Msg-based client.

     my $reply = $result_args->[0];

     # The "client" attribute was added by POE to the heap to
     # facilitate sending the correct response to the correct
     # client. All we need to do is "put" the "$reply".

     $heap->{client}->put( $reply );

     my $sessionId = $session->ID;
     $Log->write(4, "$MsgAlias: client reply sent (cid=$sessionId)");
     return;
 }

Then, to continue this example for a moment more, if the '$CmdClass'
containing the 'dispatch()' method were to determine that the incoming
message was a valid message object but an illegal commnad, the entire
response mechanism is as simple as this next method. In this case,
the '$reply' sent ('put') just above contains the following error.

 package POE::Component::GCS::Server::Cmd;

 sub _invalid_request
 {   my($class, $message, $error_text) = @_;

     $error_text ||= "invalid command";

     # We must reply with something or TCP clients will hang. 
     # Simply closing the socket results in a "no response 
     # from server" error on the client side.

     my $command  = $message->body();
     my $response = $MsgClass->new( $message, $command );
     $response->setErr( -1, $error_text );
    
     $response->route();       # return error to waiting TCP client
     return;
 }


=head1 WARNINGS

When routing message objects through file handles or sockets use caution 
with messages containing Perl 'CODE references.' While the underlying 
'Storable' module does now support passing CODE refs, this has not been 
tested here.

Also note that this class does not explicitly use POE. This allows
'light weight' scripts that run outside the full POE environment to
use this messaging protocol. When POE is not used, the 'route()'
mechanism is B<only> available when the next routing is to a remote
host. This is because the 'post' and 'call' routing semantics rely
on the POE kernel. Without POE, only the 'read' and 'write'
mechanism is available to send messages across file handles or sockets.

However, the 'addRouteTo()' and 'addRouteBack()' methods B<are> 
available outside of POE, and can be used to add 'post' and 'call'
routing. For example, if messages are sent via a 'remote route' to 
a POE-based process, that process can then 'route()' messages which
contain pre-defined 'post' and/or 'call' destinations.

When running outside of the POE environment either explicitly add a 
'remote' routing -or- use the B<routeIsRemote()> method (as shown in the 
L<Synopsis|"SYNOPSIS"> section, above) to determine if the B<route()> 
method can be called on a given message object.

=head1 DEPENDENCIES

This class depends upon the following classes:

 POE::Event::Message::Header
 POE::Event::Message::UniqueID
 POE::Driver::SysRW
 POE::Filter::Reference

 POE::Kernel (optional, but required for 'post' and 'call' message routing)

=head1 SEE ALSO

See
L<POE::Event::Message::Header> and
L<POE::Event::Message::UniqueID>.

See the POE-Component-GCS distribution available on CPAN for a complete 
working model of a Generic Client/Server that uses message-based events.

=head1 AUTHOR

Chris Cobb [no dot spam at ccobb dot net]

=head1 COPYRIGHT

Copyright (c) 2005-2010 by Chris Cobb, All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

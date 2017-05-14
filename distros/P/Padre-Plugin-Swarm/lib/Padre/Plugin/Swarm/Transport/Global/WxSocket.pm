package Padre::Plugin::Swarm::Transport::Global::WxSocket;
use strict;
use warnings;
use Wx qw( :socket );

use Padre::Wx ();
use Padre::Logger;
use Data::Dumper;
use base qw( Padre::Plugin::Swarm::Transport );

our $VERSION = '0.11';

our $KEEPALIVE_TIMER_ID = Wx::NewId;



use Class::XSAccessor
    accessors => {
        socket => 'socket',
        keepalive=>'keepalive',
        config => 'config',
        token  => 'token',
        marshal => 'marshal',
        inputbuffer=>'inputbuffer',
    };
    
sub loopback { 1 }

sub enable {
    my $self = shift;
    require Wx::Socket;
    my $servername = 'swarm.perlide.org';
    $self->connect( $servername ) ;
}

sub disable { 
    my $self = shift;
    $self->disconnect;
}

sub connect {
    my $self = shift;
    my $addr = shift;
    my $wx = $self->plugin->wx;
    
    my $sock = Wx::SocketClient->new(
        Wx::wxSOCKET_NOWAIT
    ) ;
    
    $self->{socket} = $sock;
    
    Wx::Event::EVT_SOCKET_CONNECTION( $wx, $sock,
        sub { $self->on_socket_connect(@_) },
    );

    Wx::Event::EVT_SOCKET_LOST($wx , $sock , 
        sub { $self->on_socket_lost(@_) }
    ) ;
    

    $sock->Connect( 
        $addr , # Host 
        12000,  # Port
        0       # blocking/nonblocking
    );
    
    

}

sub disconnect {
    my $self = shift;
    TRACE( "Disconnecting!" ) if DEBUG;
    $self->socket->Destroy;

    $self->keepalive->Stop if $self->keepalive;
    
    ();
}


sub on_socket_connect {
    my ($self,$sock,$wx,$evt) = @_;
    
   # my $data = $evt->GetClientData; # UNsupported ?
   TRACE( "Connected!" ) if DEBUG;
   # Send a primative session start
    my $payload =  $self->marshal->encode(
            { type=>'session' , trustme=>$self->token }
        );

    # TODO - check for errors after writing, wx only throws
    # SOCKET_LOST events, errors are for us to catch
    $sock->Write( $payload , length($payload) );
    
    
    Wx::Event::EVT_SOCKET_INPUT($wx, $sock ,
        sub { $self->on_session_start(@_ ) }
    ) ;
    

   # TODO set a timer to check for the session response
   # and do something if it does not work

}

sub on_session_start {
    my ($self,$sock,$wx,$evt) = @_;
    my $data = '';
    my $message;
    my $marshal = $self->marshal;
    while ( $sock->Read( $data , 1024,  length($data) ) ) {
        $message = eval { $marshal->incr_parse($data) }; 
        if ( $@ ) { 
            $marshal->incr_skip;
            TRACE( "Skipped unparsable incremental $@" ) if DEBUG;
        }
        last if $message;
        $data='';
    }
    TRACE( "Session start says " . Dumper $message ) if DEBUG;
    return unless $message;

    if ( $message->{session} eq 'authorized' ) {
        $self->{token} = $message->{token};
        TRACE( "Authorized with " . $message->{token} ) if DEBUG;
       
        # Now hook the event to our input filter
        Wx::Event::EVT_SOCKET_INPUT($wx, $sock ,
            sub { $self->on_socket_input(@_ ) }
        ) ;
        
        # Send any buffered messages now that the session
        # is 'authorized'
        if ($self->{write_queue}) {
            $self->write( $_ ) while shift @{ $self->{write_queue} };
        }
        
        # Notify the callback
        $self->on_connect->() if $self->on_connect;        
        
        my $timer = Wx::Timer->new( 
            $self->plugin->wx, 
            $KEEPALIVE_TIMER_ID 
        );
        $self->keepalive($timer);
        
        unless ( $timer->IsRunning ) {
                Wx::Event::EVT_TIMER(
                    $self->plugin->wx, 
                    $KEEPALIVE_TIMER_ID, 
                    sub { $self->on_timer_alarm(@_) } 
                );
                $timer->Start(5 * 60 * 1000, 0); 
        }

        
    }
    
}

sub on_timer_alarm {
    my $self = shift;
    $self->write(' ') ; # waste a packet :(
    
}

sub on_socket_lost {
    my ($self,$sock,$wx,$evt) = @_;
    TRACE( "Socket lost" ) if DEBUG;
    $self->on_disconnect->($evt)
        if $self->on_disconnect;

}

sub on_socket_input {
    my ($self,$sock,$wx,$evt) = @_;
    
    TRACE( "Socket Input" ) if DEBUG;
    my $marshal = $self->_marshal;
    
    my $data = '';
    my $buffer = $self->inputbuffer;
    if (length($buffer)) {
        TRACE( "INPUT BUFFER=$buffer" ) if DEBUG;
    }
    # Read chunks of data from the socket until there is
    # no more to read, feeding it into the decoder.
    # TODO - can we yield to WxIdle in here? .. safely?
    while ( $sock->Read( $data, 65535, 0  ) ) {
        $buffer .= $data;
        TRACE("Read chunk '$data'") if DEBUG;
        $data='';
    }

    eval { $marshal->incr_parse($buffer) }; # VOID context pls!
    
    my @messages;
    while ( my $m =  eval { $marshal->incr_parse() } ) {
        push @messages,$m;
        TRACE( 'Parsed '. @messages . ' messages' ) if DEBUG;
    } continue {
        my $fragment = $marshal->incr_text;
        $self->inputbuffer("$fragment");
    }
    if ($@) {
        if (length($buffer) < 200_000 ) {
            $self->inputbuffer($buffer);
        } else {
            TRACE( "Unparsable message, $@" ) if DEBUG;
            TRACE( "BUFFER= $buffer " ) if DEBUG;
            $self->inputbuffer('');
        }
    }

    TRACE( "Remaining input: ".$self->inputbuffer ) if DEBUG;
    
    
    
    foreach my $m ( @messages ) {
        #next unless ref $m eq 'HASH';
        
        $m->{transport} = 'global';
        my $type = $m->{type};
        my $origin = $m->{__origin_class};
        
        
        TRACE( " Got " . $m->type . " from " . $m->from ) if DEBUG;
        # Notify the on_recv callback
        $self->on_recv->($m) if $self->on_recv;
    }
    
    
    
    
}

sub write {
    my $self = shift;
    my $data = shift;
    # Only write if the session has started
    if ( $self->{token} ) {
        TRACE( "write '$data'" ) if DEBUG;
        $self->socket->Write( $data, length($data) );
    }
    else {
        TRACE( "Queue message '$data'") if DEBUG;
        push @{ $self->{write_queue} }, $data;
    }
    
}

1;

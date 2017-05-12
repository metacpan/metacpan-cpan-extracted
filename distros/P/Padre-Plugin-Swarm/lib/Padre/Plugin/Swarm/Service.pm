package Padre::Plugin::Swarm::Service;
use strict;
use warnings;
use base 'Padre::Task';
use IO::Handle;
use Padre::Logger;
use Padre::Swarm::Message;
use Data::Dumper;
use Socket;
use Storable;
use POSIX qw(:errno_h :fcntl_h);
use Carp 'croak';

{
    my %sockets = ();
    my $socketid = 1;
    sub _new_socketpair {
        my $self = shift;
        my $id = $socketid++;
        my ($read,$write) = ( IO::Handle->new() , IO::Handle->new() );
        socketpair( $read, $write, AF_UNIX, SOCK_STREAM, PF_UNSPEC ) or die $!;
        binmode $read;
        binmode $write;
        my $fd_read = $read->fileno;
        $sockets{$id} = [ $read, $write ];
        $self->{_inbound_file_descriptor} = $fd_read;
        return $self->{socketid}= $id;
    }
    
    
    sub _cleanup_socketid {
        my $self = shift;
        my $id = $self->{socketid};
        my ($read,$write) = @{ delete $sockets{$id} };
        undef $read;
        undef $write;
        return ();
    }

    
    sub _get_socketpair {
        my $self = shift;
        my $id = $self->{socketid};
        return @{ $sockets{$id} };
    }
    
}


sub new {
	shift->SUPER::new(
		prepare => 0,
		run     => 0,
		finish  => 0,
		@_,
	);
}

sub notify {
    my $self = shift;
    my $handler = shift;
    my $message = shift;
    
    eval {
        my $data = Storable::freeze( [ $handler => $message ] );
        TRACE( "Transmit storable encoded envelope size=".length($data) ) if DEBUG;
        # Cargo from AnyEvent::Handle, register_write_type =>'storable'
        my ($read,$write) = $self->_get_socketpair;
        $write->syswrite( pack "w/a*", $data );
    };
    if ($@) {
        TRACE( "Failed to send message down parent_socket , $@" );
    }
}


############## TASK METHODS #######################

sub run {
    my $self = shift;
    
    require Scalar::Util;
    
    
    # when AnyEvent detects Wx it falls back to POE (erk).
    # , tricking it into using pureperl seems to work.
    $ENV{PERL_ANYEVENT_MODEL}='Perl';
    #
    $ENV{PERL_ANYEVENT_VERBOSE} = 8 if DEBUG;
    require AnyEvent;
    require AnyEvent::Handle;
    require Padre::Plugin::Swarm::Transport::Global;
    require Padre::Plugin::Swarm::Transport::Local;
    TRACE( " AnyEvent loaded " ) if DEBUG;
    
    my $file_no = $self->{_inbound_file_descriptor};
    
    my $inbound = IO::Handle->new();
    #    
    eval { $inbound->fdopen( $file_no , 'r'); $inbound->fdopen($file_no,'w') };
    if ($@) {
        TRACE( "Failed to open inbound channel - $@ - $! ==" . $self->{inbound_file_descriptor}  );
    }
    
    
    # TRACE( "Using inbound handle $inbound" );
    my $parent_io = AnyEvent::Handle->new(
        fh => $inbound ,
        #fh => $self->{inbound_file_descriptor},
        #on_read => sub { warn "Readable @_"; shift->push_read(storable=>\&read_parent_socket)  } ,
        on_read => sub { shift->push_read( storable => sub { $self->read_parent_socket(@_) } ) },
        on_error => sub { warn "Error on parent_io channel"; },
        on_eof   => sub { warn "EOF on parent_io channel"; }
    ) or die $! ;
    TRACE( "Using AE io handle $parent_io" ) if DEBUG;
    
    #my $io = AnyEvent->io( poll => 'r' , fh => $inbound , cb => sub { $self->read_parent_socket($inbound) } );
    
    my $bailout = AnyEvent->condvar;
    
    $self->{bailout} = $bailout;
    $self->_setup_connections;
    
    my $queue_poller = AnyEvent->timer( 
        after => 0.2,
        interval => 0.2 ,
        cb => sub { $self->read_task_queue },
    );
    TRACE( "Timer - $queue_poller" ) if DEBUG;

    $self->{run}++;
    
    ## Blocking now ... until the bailout is sent or croaked
    my $exit_mode = $bailout->recv;
    TRACE( "Bailout reached! " . $exit_mode ) if DEBUG;
    undef $queue_poller;
    
    $self->_teardown_connections;
    my $cleanup = AnyEvent->condvar;
    my $graceful = AnyEvent->timer( after=>0.5, cb => $cleanup );
    ## blocking for graceful cleanup
    TRACE( "Waiting for graceful exit from transports" ) if DEBUG;
    $cleanup->recv;
    
    
    TRACE( 'returning from ->run' ) if DEBUG;
    return 0;
}

sub _setup_connections {
    TRACE( @_ ) if DEBUG;
    my $self = shift;
    
    my $global = new Padre::Plugin::Swarm::Transport::Global
                    host => 'swarm.perlide.org',
                    port => 12000;
                    
    
    TRACE( 'Global transport ' .$global ) if DEBUG;
    $global->reg_cb(
        'recv' => sub { $self->_recv('global', @_ ) }
    );
    
    $global->reg_cb(
        'connect' => sub { $self->_connect('global', @_ ) },
    );
    
    $global->reg_cb(
        'disconnect' => sub { $self->_disconnect('global', @_  ) },
    );
    
    $self->{global}  = $global;
    $global->enable;
    
    
    my $local = new Padre::Plugin::Swarm::Transport::Local;
    
    TRACE( 'Local transport ' .$local ) if DEBUG;
    $local->reg_cb(
        'recv' => sub { $self->_recv('local' ,@_ ) }
    );
    
    $local->reg_cb(
        'connect' => sub { $self->_connect('local', @_ ) },
    );
    
    $local->reg_cb(
        'disconnect' => sub { $self->_disconnect('local', @_ ) },
    );
    
    $self->{local}  = $local;
    $local->enable;
    
    
    
    
}

sub _teardown_connections {
    my $self = shift;
    TRACE( 'Teardown global' ) if DEBUG;
    local $@;
    eval { $self->{global}->event('disconnect'); };
    if ( $@ ) {
        TRACE( $@ ) if DEBUG;
    }
    
    TRACE( 'Teardown local' ) if DEBUG;
    eval { $self->{local}->event('disconnect'); };
    if ($@) {
        TRACE( $@ ) if DEBUG;
    }
    my $global = delete $self->{global};
    my $local = delete $self->{local};
    
    
    return ();
    
}

sub finish {
    TRACE( "Finished called" ) if DEBUG;
    my $self = shift;
    $self->_cleanup_socketid($self->{socketid});
    $self->{finish}++;
    return 1;
}

sub prepare {
    my $self = shift;
    $self->_new_socketpair; # mutator , need to know.
    $self->{prepare}++;
    return 1;
}

sub send_global {
    my $self = shift;
    my $message = shift;
    TRACE( "Sending GLOBAL message %$message" ) if DEBUG;
    $self->{global}->send($message);
    
}


sub send_local {
    my $self = shift;
    my $message = shift;
    TRACE( "Sending LOCAL message %$message" ) if DEBUG;
    $self->{local}->send($message);
    
}


sub shutdown_service {
    my $self = shift;
    my $reason = shift;
    TRACE( 'Shutdown service with reason ' . $reason ) if DEBUG;
    $self->{bailout}->send($reason);
}

sub read_parent_socket {
    my ($self,$inbound,$envelope) = @_;
    unless ( ref $envelope eq 'ARRAY' ) {
        TRACE( 'Unknown inbound envelope message: ' . Dumper $envelope );
        return;
    }
    
    my ($method,@args) = @$envelope;
    local $@;
    eval { $self->$method(@args) };
    if ($@) {
        TRACE( 'Method dispatch failed with ' . $@ . ' for ' . Dumper $envelope );
    }
    
}

sub read_task_queue {
    my $self = shift;
    
    # We're probably NOT receiving anything from parent calling ->tell_child
    #  that would be in the child_inbox, this can become a periodic poll for 
    #   $self->cancelled ONLY.
    eval {
        # while( my $message = $self->child_inbox ) {
                # my ($method,@args) = @$message;
                # local $@;
                # eval { $self->$method(@args);};
                # if ($@) {
                    # TRACE( $@ ) ;
                # }
        # }
        
        if ( $self->cancelled ) {
            TRACE( 'Cancelled! - bailing out of event loop' ) if DEBUG;
            $self->{bailout}->send('cancelled');
        }
        
     };
    
    if ($@) {
        TRACE( 'Task queue error ' . $@ )
    }
    return;
}

sub _recv {
    my($self,$origin,$transport,$message) = @_;
    TRACE( "$origin  transport=$transport, %$message" ) if DEBUG;
    # Our caller either screwed up arguments or passed something odd.
    # TODO - let Service interrogate the $transport->origin ??
    croak "Origin '$origin' incorrect" unless ($origin=~/global|local/);
    # skip noop 
    return if $message->type eq 'noop';
    
    $message->{origin} = $origin;
    
    $self->tell_owner( $message );
    
}

sub _connect {
    my $self = shift;
    my $origin = shift;
    my $transport = shift;
    my $message = shift;
    TRACE( "Connected $origin" ) if DEBUG;
    $self->tell_status( "Swarm $origin transport connected" );
    # TODO this is a service event - NOT a swarm message. 
    my $m = [ 'connect_'.$origin , $message ];
    $self->tell_owner( $m );
}


sub _disconnect {
    my $self = shift;
    my $origin = shift;
    my $message = shift;
    TRACE( "Disconnected $origin" ) if DEBUG;
    $self->tell_status("Swarm $origin transport DISCONNECTED");
    my $m = [ 'disconnect_'.$origin , 1 ];
    $self->tell_owner( $m );
}

1;

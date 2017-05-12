package POEx::HTTP::Server;

use strict;
use warnings;

use Carp qw( carp croak confess cluck );

use POE;
use POE::Wheel::SocketFactory;
use POE::Session::PlainCall;
use POE::Session::Multiplex qw( ev evo evos ), 0.0500;
use POEx::HTTP::Server::Error;
use POEx::URI;
use Data::Dump qw( pp );
use Scalar::Util qw( blessed );
use Storable qw( dclone );

our $VERSION = '0.0902';

sub DEBUG () { 0 and  not $INC{'Test/More.pm'} }


##############################################################################
# Methods common to both the Server and the Client
package POEx::HTTP::Server::Base;

use strict;
use warnings;

use POE;
use POE::Session::PlainCall;
use HTTP::Status;
use Carp;
use Carp::Heavy;

use Data::Dump qw( pp );

BEGIN { *DEBUG = \&POEx::HTTP::Server::DEBUG }

# Virtual methods
sub _psm_begin { die "OVERLOAD ME" }
sub _psm_end   { return }
sub _stop { return }
sub error { return }
sub shutdown { return }


#######################################
# record the current running state
sub state
{
    my( $self, $state ) = @_;
    my $rv = $self->{state};
    if( 2==@_ ) {
        $self->{state} = $state;
        $self->{S} = { $state => 1 };
    }
    return $rv;
}

#######################################
sub D
{
    my $self = shift;
    $self->_D( 1, @_ );
}

sub D1
{
    my $self = shift;
    $self->_D(2,@_);
}

sub _D
{
    my $self = shift;
    my $level = shift;
    my $prefix = "$$:$self->{name}:";
    $prefix .= "$self->{state}:" if $self->{state};
    my $msg = join '', @_;
    $msg =~ s/^/$prefix /m;
    $DB::single = 1;
    unless( $msg =~ /\n$/ ) {
        my %i = Carp::caller_info($level);
        $msg .= " at $i{file} line $i{line}\n";
    }
    print STDERR $msg;
}

#######################################
# Dispatch a call to a special handler
sub special_dispatch
{
    my( $self, $why, @args ) = @_;

    my $handler = $self->{specials}{$why};
    return unless $handler;
    $self->invoke( $why, $handler, @args );
}

#######################################
# Invoke an HTTP or special handler
sub invoke
{
    my( $self, $why, $handler, @args ) = @_;
    DEBUG and $self->D( "Invoke handler for '$why' ($handler)" );
    eval { $poe_kernel->call( @$handler, @args ) };
    if( $@ ) {
        warn $@;
        if( $self->{resp} ) {
            $self->{resp}->error( RC_INTERNAL_SERVER_ERROR, $@ );
        }
    }
}

#######################################
sub net_error
{
    my( $self, $op, $errnum, $errstr ) = @_;
    unless( $self->{specials}{on_error} ) {
        # skip out early
        $self->D( "$op error ($errnum) $errstr" );
        die "$$: Failed to bind\n" if $op eq 'bind' and $errnum == 98;
        return;
    }

    DEBUG and $self->D( "$op error ($errnum) $errstr" );

    my $err = POEx::HTTP::Server->build_error;
    $err->details( $op, $errnum, $errstr );        
    $self->special_dispatch( on_error => $err );
}












##############################################################################
package POEx::HTTP::Server;

use base qw( POEx::HTTP::Server::Base );


#######################################
sub spawn
{
    my( $package, %options ) = @_;
    my $self = $package->new( %options );
    my $session = $self->build_session;
    return $self->{alias};
}

#######################################
sub new
{
    my( $package, %options ) = @_;
    my $self = bless {}, $package;
    $self->__init( \%options );
    $self->state( 'new' );
    return $self;
}

#######################################
sub __init
{
    my( $self, $opt ) = @_;
    $self->{N} = 1;
    $self->{C} = 0;

    $self->{options} = delete $opt->{options};
    $self->{options} ||= {};

    $self->{headers} = delete $opt->{headers};
    $self->{headers} ||= { Server => join '/', ref( $self ), $VERSION };

    $self->{retry} = delete $opt->{retry};
    $self->{retry} = 60 unless defined $self->{retry};

    $self->{concurrency} = delete $opt->{concurrency};
    $self->{concurrency} = -1 unless defined $self->{concurrency};

    $self->{prefork} = delete $opt->{prefork};

    $self->{inet}   = delete $opt->{inet};
    my $I = $self->{inet} || {};
    $I->{Listen} ||= 1;
    $I->{Reuse}     = 1  unless defined $I->{Reuse};
    $I->{LocalPort} = 80 unless defined $I->{LocalPort};
    $I->{BindAddr} = delete $I->{LocalAddr} 
                if $I->{LocalAddr} and not defined $I->{BindAddr};
    $I->{BindPort} = delete $I->{LocalPort} 
                if $I->{LocalPort} and not defined $I->{BindPort};

    $self->{alias} = delete $opt->{alias};
    $self->{alias} ||= 'HTTPd';
    $self->{name} = $self->{alias};

    if( $opt->{error} ) {
        $self->{error}  = POEx::URI->new( delete $opt->{error} );
    }

    $self->{blocksize} = delete $opt->{blocksize};
    $self->{blocksize} ||= 5*1500;   # 10 ethernet frames

    $self->{keepalive} = delete $opt->{keepalive};
    if( defined $self->{keepalive} and $self->{keepalive} and
            ( $self->{keepalive} !~ /^\d+$/ or $self->{keepalive} == 1) ) {
        # Apache 1 default
        #$self->{keepalive} = 15;
        # Apache 2 default
        $self->{keepalive} = 100;
    }
    $self->{keepalive} ||= 0;
    # warn "keepalive=$self->{keepalive}";

    $self->{timeout} = delete $opt->{timeout};
    if( not defined $self->{timeout} ) {
        # Apache 1 default
        #$self->{timeout} = 1200;
        # Apache 2 default
        $self->{timeout} = 300;
    }

    $self->{keepalivetimeout} = delete $opt->{keepalivetimeout};
    if( not defined $self->{keepalivetimeout} and $self->{keepalive} ) {
        # Apache 1 default
        #$self->{keepalivetimeout} = 15;
        # Apache 2 default
        $self->{keepalivetimeout} = 5;
    }

#    if( $self->{concurrency} > 0 and $self->{prefork} ) {
#        croak "Concurrency and prefork are incompatible.  Choose one or the other";
#    }

    $self->__init_handlers( $opt );
}

#######################################
sub __is_special    
{ 
    $_[0] =~ /^(on_error|on_connect|on_disconnect|pre_request|stream_request|post_request)$/;
}
sub __init_handlers
{
    my( $self, $opt ) = @_;
    $self->{handlers} = delete $opt->{handlers};

    # handler => URI
    unless( $self->{handlers} ) {
        croak "Missing required handler or handlers param" 
                unless $self->{handler};
        $self->{handlers} = { '' => delete $self->{handler} };
    }
    $self->{todo} = [];
    # handlers => URI
    unless( ref $self->{handlers} ) {
        $self->{todo} = [ '' ];
        $self->{handlers} = { '' => $self->{handlers} };
    }
    # handlers => { match => URI, ... }
    elsif( 'HASH' eq ref $self->{handlers} ) {
        $self->{todo} = [ keys %{ $self->{handlers} } ];
    }
    # handlers => [ match => URI, ... }
    else {
        my %h;
        while( @{ $self->{handlers} } ) {
            my $re = shift @{ $self->{handlers} };
            push @{ $self->{todo} }, $re unless __is_special( $re );
            $h{$re} = shift @{ $self->{handlers} };
        }
        $self->{handlers} = \%h;
    }

    # Get a list of special handlers
    my $H = $self->{handlers};
    my $S = $self->{specials} = {};

    foreach my $re ( keys %$H ) {
        $H->{$re} = POEx::URI->new( $H->{$re}, 'poe' ) unless blessed $H->{$re};
        next unless __is_special( $re );
        $S->{$re} = delete $H->{$re};
    }
    return;
}

#######################################
sub build_session
{
    my( $self ) = @_;

    my $package = __PACKAGE__;
    return POEx::HTTP::Server::Session->create( 
                      options => $self->{options}, 
                      package_states => [
                            'POEx::HTTP::Server::Base' =>
                                [ qw( _psm_begin _stop 
                                      error shutdown ) ],
                            $package => [ 
                                qw( _start build_server
                                    accept retry do_retry close
                                    handlers_get handlers_add handlers_remove
                                    prefork_child prefork_accept error
                                    prefork_parent prefork_shutdown
                                ) ],
                            'POEx::HTTP::Server::Client' => [ 
                                qw( input timeout 
                                    respond send 
                                    sendfile_start
                                    flushed done error
                            ) ]
                      ],
                      args => [ $self ],
                      heap => { O=>$self }
                    );
}

#######################################
sub build_handle
{
    my( $self ) = @_;
    return %{ $self->{inet} };
}

#######################################
sub build_error
{
    my( $package, $uri ) = @_;
    $uri ||= '/';
    return POEx::HTTP::Server::Error->new( HTTP::Status::RC_INTERNAL_SERVER_ERROR() );
}

#######################################
sub build_server
{
    my( $self ) = @_;
    DEBUG and $self->D( "build_server" );
    my %invoke = $self->build_handle;
    DEBUG and $self->D( pp \%invoke );
    $self->{server} = POE::Wheel::SocketFactory->new(
            %invoke,
            SuccessEvent => ev 'accept',
            FailureEvent  => ev 'error'
        );
    return;
}

sub drop
{
    my( $self ) = @_;
    DEBUG and $self->D( "drop" );
    delete $self->{server};
    return;
}


#######################################
sub _start
{
    my( $package, $self ) = @_;
    DEBUG and $self->D( "_start" );
    $poe_kernel->alias_set( $self->{alias} );
    poe->session->object( HTTPd => $self );
    return;
}

sub _psm_begin
{
    my( $self ) = @_;
    DEBUG and $self->D( "setup" );
    $self->state( 'listen' );
    $poe_kernel->sig( shutdown => ev"shutdown" );
    $self->build_server;
    if( $self->{prefork} ) {
        $self->__init_prefork;
        $self->{server}->pause_accept;
    }
}

sub done
{
    my( $self ) = @_;
    DEBUG and $self->D( "done" );
    poe->session->object_unregister( 'HTTPd' );
}


#######################################
sub _stop
{
    my( $package ) = @_;
    my $self = poe->heap->{O};
    DEBUG and $self->D( "_stop" );
}

#######################################
sub shutdown
{
    my( $self ) = @_;
    $self->state( 'shutdown' );
    DEBUG and $self->D( "Shutdown" );
    $poe_kernel->alias_remove( delete $self->{alias} ) if $self->{alias};
    foreach my $name ( keys %{ $self->{clients}||{} } ) {
        DEBUG and $self->D( "shutdown client=$name" );
        $poe_kernel->yield( evo $name => 'shutdown' );
    }
    $self->drop;
}

#######################################
sub accept
{
    my( $self, $socket, $peer ) = @_;
    
    # T->start( 'connection' );
    DEBUG and $self->D( "accept" );
    $self->state( 'accept' );

    my $obj = $self->build_client( $self->{N}++, $socket );
    poe->session->object( $obj->name, $obj );
    $obj->build_wheel( $socket );
    # Starting the timeout here prevents the client from keeping a connection
    # open by never sending a request
    $obj->timeout_start;

    $self->concurrency_up;
    $self->{clients}{$obj->name} = 1;
    DEBUG and $self->D( "accept ".$obj->name." socket=".$socket );
    $self->prefork_accepted;

    $self->state( 'listen' );
}

sub close
{
    my( $self, $name ) = @_;
    DEBUG and 
        $self->D( "close $name" );

    $self->concurrency_down;
    delete $self->{clients}{$name};

    # Only close if we really are closed...
    if( $self->{C} == 0 ) {
        $self->prefork_close;
    }

    unless( $self->{C} > 0 or $self->{server} ) {
        $self->done;
    }
}

sub concurrency_up
{
    my( $self ) = @_;
    $self->{C}++;
    return unless $self->{concurrency} > 0;
    if( $self->{C} >= $self->{concurrency} ) {
        DEBUG and 
            $self->D( "pause_accept C=$self->{C}" );
        $self->{server}->pause_accept;
        $self->{paused} = 1;
    }
}

sub concurrency_down
{
    my( $self ) = @_;
    $self->{C}--;
    return unless $self->{concurrency} > 0;
    unless( $self->{C} >= $self->{concurrency} and $self->{paused} ) {
        if( $self->{server} ) {
            DEBUG and 
                $self->D( "resume_accept C=$self->{C}" );
            $self->{server}->resume_accept;
        }
        $self->{paused} = 0;
    }
}

#######################################
sub error
{
    my( $self, $op, $errnum, $errstr, $id ) = @_;
    
    $self->net_error( $op, $errnum, $errstr );
    delete $self->{server};

    $self->retry;
}

#######################################
sub retry
{
    my( $self ) = @_;
    return unless $self->{retry};
    my $tid = $poe_kernel->delay_set( ev"do_retry" => $self->{retry} );
    DEBUG and $self->D( "Retry in $self->{retry} seconds.  tid=$tid." );
    return $tid;
}

#######################################
sub do_retry
{
    my( $self ) = @_;
    DEBUG and $self->D( "do_retry" );
    $self->build_server;
}




#######################################
sub handlers_get
{
    my( $self ) = @_;
    my $ret = dclone $self->{handlers};
    my $S = dclone $self->{specials};
    @{ $ret }{ keys %$S } = values %$S;
    return $ret;
}

#######################################
sub handlers_set
{
    my( $self, $H ) = @_;
    $self->__init_handlers( { handlers=>$H } );
    return 1;
}

#######################################
sub handlers_add
{
    my( $self, $new ) = @_;
    return unless defined $new;
    my $H = $self->{handlers};
    my $S = $self->{specials};
    my $T = $self->{todo};
    $self->__init_handlers( {handlers=>$new} );
    delete @{ $S }{ keys %{ $self->{specials} } };
    @{ $self->{specials} }{ keys %$S } = values %$S;

    delete @{ $H }{ keys %{ $self->{handlers} } };
    my @todo;
    foreach my $re ( @$T ) {
        next if $self->{handlers}{$re};
        push @todo, $re;
    }
    push @todo, @{ $self->{todo} };
    $self->{todo} = \@todo;
    @{ $self->{handlers} }{ keys %$H } = values %$H;

    return 1;
}

#######################################
sub handlers_remove
{
    my( $self, $del ) = @_;
    my @list;
    my %R;
    unless( ref $del ) {
        @list = $del;
    }
    elsif( 'HASH' eq ref $del ) {
        @list = keys %$del;        
    }
    else {
        @list = @$del;
    }
    foreach my $re ( @list ) {
        if( __is_special( $re ) ) {
            delete $self->{specials}{ $re };
        }
        else {
            $R{$re} = 1;
            delete $self->{handlers}{ $re };
        }
    }

    my @todo;
    foreach my $re ( @{ $self->{todo} } ) {
        next if $R{$re};
        push @todo, $re;
    }
    $self->{todo} = \@todo;
}


#######################################
sub __init_prefork
{
    my( $self ) = @_;
    return unless $self->{prefork};
    DEBUG and $self->D( "__init_prefork" );

    $self->{parent} = 1;
    $poe_kernel->sig( daemon_child => ev 'prefork_child' );
    $poe_kernel->sig( daemon_parent => ev 'prefork_parent' );
    $poe_kernel->sig( daemon_accept => ev 'prefork_accept' );
    $poe_kernel->sig( daemon_shutdown => ev 'prefork_shutdown' );
}

#######################################
sub prefork
{
    my( $package, $status ) = @_;
    $poe_kernel->call( Daemon => update_status => $status );
}

#######################################
# Called to tell us we are the child
sub prefork_child
{
    my( $self ) = @_;
    DEBUG and 
        $self->D( "prefork_child" );
    delete $self->{parent};
    $self->prefork( 'wait' );
}

#######################################
# Called when we are the child, and we move to wait state
sub prefork_accept
{
    my( $self ) = @_;
    DEBUG and 
        $self->D( "prefork_accept resume_once=".($self->{resume_once}||'') );
    if( $self->{resume_once} ) {
        # Daemon->peek( 1 );
    }
    else {
        $self->{resume_once} = 1;
        $self->{server}->resume_accept;
    }
}

#######################################
# Called when a new connection opens
sub prefork_accepted
{
    my( $self ) = @_;
    DEBUG and $self->D( "prefork_accepted" );
    return unless $self->{prefork};
    $self->prefork( 'req' );
    # 2012/07 - server handles the pause_accept() etc in concurrency_down
    #$self->{server}->pause_accept unless $self->{concurrency} > 1;
}

#######################################
# Called when a connection is closed
sub prefork_close
{
    my( $self ) = @_;
    DEBUG and 
        $self->D( "prefork_close" );
    return unless $self->{prefork};
    $self->prefork( 'done' );
}

#######################################
# Called when it is clear we are the parent
sub prefork_parent 
{
    my( $self ) = @_;
    DEBUG and 
        $self->D( "prefork_parent" );
    $self->{parent} = $$;
}

#######################################
sub prefork_shutdown
{
    my( $self ) = @_;
    DEBUG and 
        $self->D( "prefork_shutdown" );
    $self->shutdown;
}

#######################################
sub build_client
{
    my( $self, $N, $socket ) = @_;
    my $name = join '-', $self->{alias}, $N;
    return POEx::HTTP::Server::Client->new( 
                    socket  => $socket,
                    __close => ev"close",
                    alias => $self->{alias}, 
                    name  => $name, 
                    todo  => $self->{todo},
                    handlers => dclone $self->{handlers},
                    specials => dclone $self->{specials},
                    headers => $self->{headers},
                    error   => $self->{error},
                    blocksize => $self->{blocksize},
                    timeout   => $self->{timeout},
                    keepalive => $self->{keepalive},
                    keepalivetimeout => $self->{keepalivetimeout},
                );
}

##############################################################################
package POEx::HTTP::Server::Client;

use strict;
use warnings;

use Carp;
use HTTP::Status;
use POE;
use POE::Wheel::ReadWrite;
use POE::Filter::HTTPD;
use POEx::HTTP::Server::Request;
use POEx::HTTP::Server::Response;
use POEx::HTTP::Server::Connection;
use POEx::HTTP::Server::Error;
use POE::Session::PlainCall;
use POE::Session::Multiplex qw( ev evo rsvp );
use POE::Filter::Stream;

use base qw( POEx::HTTP::Server::Base );

use Data::Dump qw( pp );

BEGIN { *DEBUG = \&POEx::HTTP::Server::DEBUG }
# sub DEBUG () { 1 }

our $HAVE_SENDFILE;
BEGIN {
    unless( defined $HAVE_SENDFILE ) {
        $HAVE_SENDFILE = 0;
        eval "
            use Sys::Sendfile 0.11;
        ";
        # warn $@ if $@;
        $HAVE_SENDFILE = 1 unless $@;
    }
}

#######################################
sub new
{
    my( $package, %param ) = @_;

    my $self = bless { %param }, $package;
    $self->state( 'waiting' );
    $self->build_connect( delete $self->{socket} );
    return $self;

}

sub name () { $_[0]->{name} }

#######################################
sub build_wheel
{
    my( $self, $socket ) = @_;

    my $filter = $self->build_filter;
    $self->{wheel} = POE::Wheel::ReadWrite->new( 
                        Handle => $socket,
                        InputEvent => evo( $self->{name}, 'input' ),
                        ErrorEvent => evo( $self->{name}, 'error' ),
                        FlushedEvent => evo( $self->{name}, 'flushed' ),
                        Filter     => $filter
                    );
}

sub build_filter
{
    return POE::Filter::HTTPD->new;
}

sub build_stream_filter
{
    return POE::Filter::Stream->new;
}

sub build_connect
{
    my( $self, $socket ) = @_;
    $self->{connection} = 
                POEx::HTTP::Server::Connection->new( $self->{name}, $socket );
}


sub build_response
{
    my( $self ) = @_;
    my $resp = POEx::HTTP::Server::Response->new(RC_OK);
    $resp->header( 'X-PID' => $$ );
    $resp->request( $self->{req} ) if $self->{req};
    $resp->{__respond} = rsvp"respond";
    $resp->{__send} = rsvp"send";
    $resp->{__sendfile} = rsvp"sendfile_start";
    $resp->{__done} = rsvp"done";
    return $resp;
}

#######################################
sub _psm_begin
{
    my( $self ) = @_;
    $self->on_connect;
}

#######################################
sub on_connect
{
    my( $self ) = @_;
    $self->special_dispatch( on_connect => $self->{connection} );
}

sub on_disconnect
{
    my( $self ) = @_;
    $self->special_dispatch( on_disconnect => $self->{connection} );
}

#######################################
sub error
{
    my( $self, $op, $errnum, $errstr, $id ) = @_;

    if( $op eq 'read' and $errnum == 0 ) {  
        # this is a normal error
        DEBUG and 
            $self->D( "$op error ($errnum) $errstr" );
    }
    else {
        $self->net_error( $op, $errnum, $errstr );
    }

    # 2013-04 - We use ->yield and not ->close so that POE can empty the
    # queue of all events provoked by the last select().  This way the
    # explicit socket->close will not cause problems.
    $poe_kernel->yield( ev "close" );
}

#######################################
sub close
{
    my( $self ) = @_;
    $self->state( 'closing' );
    DEBUG and 
        $self->D( "Close" );
    $poe_kernel->yield( $self->{__close}, $self->name );
    poe->session->object_unregister( $self->{name} );
    $self->on_disconnect;
    $self->close_connection;
    $self->keepalive_stop;
    $self->timeout_stop;
    # use POE::Component::Daemon;
    # Daemon->peek( 1 );
}

sub close_connection
{
    my( $self ) = @_;
    DEBUG and $self->D( "close_connection" );
    my $C = delete $self->{connection};
    $C->{aborted} = 1;
    my $W = delete $self->{wheel};
    if( $W ) {
        my $socket = $W->get_input_handle;
        $W->DESTROY;
        if( $socket ) {
            DEBUG and $self->D( "Shutdown socket=$socket" );
            # Do an explicit shutdown, for Windows problems
            shutdown( $socket, 2 );
            $socket->close;
        }
    }
    # T->end( 'connection' );
    return;
}

sub drop
{
    my( $self ) = @_;
    delete $self->{req};
    delete $self->{resp};
}


#######################################
sub input
{
    my( $self, $req ) = @_;
    # T->start( 'REQ' );
    DEBUG and $self->D( "input" );

    $self->state( 'handling' );

    # stop the timer that was started on accept
    $self->timeout_stop;
    # stop any keepalive timer we might have
    $self->keepalive_stop;

    if( $self->{req} ) {
        warn "New request while we still have a request";
        $self->pending_push( $req );
        return;
    }

    if ( $req->isa("HTTP::Response") ) {
        $self->input_error( $req );
        return;
    }

    # Rebless to our package
    $self->{req} = bless $req, 'POEx::HTTP::Server::Request';
    $req->connection( $self->{connection} );

    # Tell the user code
    $self->special_dispatch( 'pre_request', $req );

    # Build response
    $self->{resp} = $self->build_response;
    $self->reset_req;

    $self->dispatch;
}

sub input_error
{
    my( $self, $resp ) = @_;
    DEBUG and $self->D( "ERROR ", $resp->status_line );
    bless $resp, 'POEx::HTTP::Server::Error';
    $self->special_dispatch( on_error => $resp );
    $self->{req} = POEx::HTTP::Server::Request->new( ERROR => '/' );
    $self->{req}->connection( $self->{connection} );
    $self->{req}->protocol( "HTTP/1.1" );
    $self->{resp} = $resp;
    $self->reset_req;
    $self->{shutdown} = 1;

    $self->respond;
}

sub reset_req
{
    my( $self ) = @_;
    
    if( delete $self->{stream_wheel} ) {
        # Second request on a keep-alive wheel.  Switch back to Filter::HTTPD
        $self->{wheel}->set_output_filter( $self->build_filter );
    }
    $self->{will_close} = 0;
    $self->{once} = 0;
    $self->{flushing} = 0;
}

#######################################
sub output
{
    my( $self, $something ) = @_;

    $self->{flushing} = 1;
    # T->point( REQ => 'output' );
    $self->{wheel}->put( $something );
}

#######################################
## POE::Wheel::ReadWrite is telling us that what we wrote has been written
sub flushed 
{
    my( $self ) = @_;

    $self->{flushing} = 0;
    DEBUG and $self->D( "Flushed" );
    
    # wrote a bit of a file
    if( $self->{sendfile} ) {           
        return $self->sendfile_next;    # send some more
    }

    # Request has finished
    if( not $self->{resp} or $self->{S}{done} or $self->{resp}->finished ) {
        return $self->finish_request;
    }

    # streaming?
    elsif( $self->{resp}->streaming ) {     
        return $self->send_more;        # send some more
    }

    # The last possiblity is that calls to ->send have filled up the Wheel's
    # or the driver's buffer and it was flushed.
}




#######################################
# Clean up after a request
sub finish_request
{
    my( $self ) = @_;
    $self->state( 'done' );
    DEBUG and $self->D( 'finish_request' );

    if( $self->keepalive_start ) {
        # if we have keepalive set, then we don't need the TCP timeout
        $self->timeout_stop;
    }
    # If we don't have a keepalive, {will_close} will be true and that will
    # force a socket close

    # next 3 MUST be in this order if we want post_request to always come 
    # before on_disconnect (which is posted from ->close()) 
    $self->special_dispatch( 'post_request', $self->{req}, $self->{resp} );
    $self->close if $self->{will_close};
    $self->drop;
    $self->pending_next;
    # T->end( 'REQ' );
}





#######################################
sub dispatch
{
    my( $self ) = @_;
    my $path = $self->{req} && $self->{req}->uri ?
                               $self->{req}->uri->path : '/';

    my( $why, $handler ) = $self->find_handler( $path );
    if( $handler ) {
        # T->point( REQ => "handler $re" );
        $self->invoke( $why, $handler, $self->{req}, $self->{resp} );
    }
    else {
        $self->{resp}->error( RC_NOT_FOUND, "No handler for path $path.\n" );
    }
}
        
#######################################
sub find_handler
{
    my( $self, $path ) = @_;
    DEBUG and $self->D( "Request for $path" );
    foreach my $re ( @{ $self->{todo} } ) {
        next unless $re eq '' or $path =~ /$re/;
        return( $re, $self->{handlers}{$re} );
    }
    return;
}

#######################################
sub respond
{
    my( $self ) = @_;

    DEBUG and $self->D( "respond" );
    # XXX - make this next bit a POE-croak
    confess "Responding more then once to a request" if $self->{once}++;

    unless( $self->{resp}->headers_sent ) {
        $self->should_close;
        $self->send_headers;
    }

    $self->{resp}->content( undef() );
    $self->timeout_start();
    return;
}

sub send_headers
{
    my( $self ) = @_;

    DEBUG and $self->D( "Response: ".$self->{resp}->status_line );
    $self->__fix_headers;
    $self->output( $self->{resp} );
    $self->{resp}->headers_sent( 1 );
}



#######################################
sub __fix_headers
{
    my( $self ) = @_;
    while( my( $h, $v ) = each %{$self->{headers}} ) {
        next if $self->{resp}->header( $h );
        $self->{resp}->header( $h => $v);
    }

    # Tell the browser the connection should close
    if( $self->{will_close} and $self->{req} and $self->{req}->protocol eq 'HTTP/1.1' ) {
        my $c = $self->{resp}->header( 'Connection' );
        if( $c ) { $c .= ",close" }
        else { $c = 'close' }
        $self->{resp}->header( 'Connection', $c );
    }
}

#######################################
sub should_close
{
    my( $self ) = @_;
    $self->{will_close} = 1;
    if ( $self->{req} and $self->{req}->protocol eq 'HTTP/1.1' ) {
        $self->{will_close} = 0;                   # keepalive
        # It turns out the connection field can contain multiple
        # comma separated values
        my $conn = $self->{req}->header('Connection')||'';
        $self->{will_close} = 1 if qq(,$conn,) =~ /,\s*close\s*,/i;
        #warn "$$:conn=$conn will_close=$self->{will_close}";
        # Allow handler code to control the connection
        $conn = $self->{resp}->header('Connection')||'';
        $self->{will_close} = 1 if qq(,$conn,) =~ /,\s*close\s*,/i;
        #warn "$$:conn=$conn will_close=$self->{will_close}";
    }
    else {
        # HTTP/1.0-style keep-alives fail
        #my $conn = $self->{req}->header('Connection')||'';
        #$self->{will_close} = 0 if qq(,$conn,) =~ /,\s*keep-alive\s*,/i;
        #warn "$$:conn=$conn will_close=$self->{will_close}";
    }

    $self->{will_close} = 1 if $self->{resp}->streaming;
    #warn "$$:post streaming will_close=$self->{will_close}";
    $self->{will_close} = 1 unless $self->{keepalive} > 1;
    #warn "$$:post keepalive will_close=$self->{will_close}";
    $self->{will_close} = 1 if $self->{shutdown};
    DEBUG and 
        $self->D( "will_close=$self->{will_close}" );
    return $self->{will_close};
}

#######################################
sub send
{
    my( $self, $something ) = @_;
    DEBUG and $self->D("send");
    confess "Responding more then once to a request" unless $self->{resp};
    unless( $self->{resp}->headers_sent ) {
        $self->should_close;
        $self->send_headers;
        $self->{stream_wheel} = 1;
        $self->{wheel}->set_output_filter( $self->build_stream_filter );
        if( $self->{resp}->streaming ) {
            eval { 
                $SIG{__DIE__} = 'DEFAULT'; 
                $self->__tcp_hot;
            };
            warn $@ if $@;
        }
    }

    $self->output( $something ) if defined $something;
    if( $self->{resp}->streaming and $self->{wheel} ) {
        $self->{wheel}->flush;            
    }
    $self->timeout_start();
    return;
}

# We are in streaming mode.  The last chunk has flushed.  Send a new one
sub send_more
{
    my( $self ) = @_;
    $self->timeout_stop();
    $self->special_dispatch( 'stream_request', $self->{req}, $self->{resp} );
}


# We are in streaming mode.  Turn off Nagle's algorithm
# This isn't as effective as you might think
sub __tcp_hot
{
    my( $self ) = @_;
    DEBUG and 
        $self->D( "TCP_NODELAY" );
    my $h = $self->{wheel}->get_output_handle;
    setsockopt($h, Socket::IPPROTO_TCP(), Socket::TCP_NODELAY(), 1) 
        or die "setsockopt TCP_NODELAY: $!";
    
    # Note: On linux, even if we set the buffer size to 576, the minimum
    # is 2048.  However, this still allows us to by-pass Nagle's algorithm.
    setsockopt($h, Socket::SOL_SOCKET(), Socket::SO_SNDBUF(), 576)
        or die "setsockopt SO_SNDBUF: $!";
    
    DEBUG and $self->D( "SO_SNDBUF=", unpack "i",
                    getsockopt($h, Socket::SOL_SOCKET(), Socket::SO_SNDBUF()));
    
}

sub __tcp_sndbuf
{
    my( $self ) = @_;
    my $h = $self->{wheel}->get_output_handle;
    my $bs = eval {
            $SIG{__DIE__} = 'DEFAULT';
            return unpack "i", getsockopt($h, Socket::SOL_SOCKET(), Socket::SO_SNDBUF());
        };
    return $bs;
}

#######################################
# Send an entire file
# This is a callback from Response
# $path is what should be reported in errors
# $file is the full path to a readable file
# $size is the amount of the file to send.  Should be entire file.
sub sendfile_start
{
    my( $self, $path, $file, $size ) = @_;

    die "Already sending a file" if $self->{sendfile};

    DEBUG and $self->D( "sendfile path=$path size=$size" );

    # Open the file
    my $fh = IO::File->new;
    unless( $fh->open($file) ) {
        $self->{resp}->error(RC_INTERNAL_SERVER_ERROR, "Unable to open $path: $!" );
        return;
    }

    $self->{sendfile} = { offset=>0, size=>$size, fh=>$fh, 
                          path=>$path, bs=>$self->{blocksize} };
    $self->send;
    # we wait for the 'flush' event to invoke sendfile.
    $self->timeout_start();
}

sub sendfile_next
{
    my( $self ) = @_;

    my $S = $self->{sendfile};
    use bytes;

    my $len;
    if( $HAVE_SENDFILE ) {
        DEBUG and $self->D( "sendfile path=$S->{path} offset=$S->{offset}" );
        my $socket = $self->{wheel}->get_output_handle;
        $len = sendfile( $socket, $S->{fh}, 0, $S->{offset} );
        unless( defined $len ) {
            $self->net_error( 'sendfile', 0+$!, "$!" );
            return;
        }
        $poe_kernel->select_resume_write( $socket );
    }
    else {
        DEBUG and $self->D( "sysread path=$S->{path} offset=$S->{offset}" );
        my $c = '';
        $len = sysread( $S->{fh}, $c, $S->{bs} );
        if( $len > 0 ) {
            DEBUG and $self->D( "send bytes=".length $c );
            $self->send( $c );
        }
    }
    $S->{offset} += $len;
    if( $S->{offset} >= $S->{size} ) {
        DEBUG and $self->D( "sendfile done" );
        $self->D( "Sendfile sent to many bytes!" ) if $S->{offset} > $S->{size};
        $self->done;
        delete $self->{sendfile};
    }
    $self->timeout_start();
    return $len;
}


#######################################
sub done
{
    my( $self ) = @_;
    $self->state( 'done' );
    DEBUG and $self->D( "Done" );
    # If we don't have a {req}, then the request has already finished
    # But wait until request is flushed to finish it.
    if( not $self->{flushing} and $self->{req} ) {
        $self->finish_request;
    }
}

#######################################
sub keepalive_start
{
    my( $self ) = @_;
    # $self->D( "will_close=$self->{will_close} keepalive=$self->{keepalive}" );
    return if $self->{will_close};
    $self->{keepalive}--;
    return unless $self->{keepalive} > 0;
    DEBUG and 
            $self->D( "keep-alive=$self->{keepalive}" );
    DEBUG and $self->D( "keep-alive timeout=$self->{keepalivetimeout}" );
    $self->{KAID} = $poe_kernel->delay_set( ev"timeout", 
                                               $self->{keepalivetimeout} 
                                             );
    DEBUG and $self->D1( "keep-alive start tid=$self->{KAID}" );
    $self->state( 'waiting' );
    return 1;
}

#######################################
sub timeout
{
    my( $self ) = @_;
    $self->keepalive_stop;
    $self->timeout_stop;
    $self->close;
}

#######################################
sub keepalive_stop
{
    my( $self ) = @_;
    return unless $self->{KAID};
    DEBUG and $self->D1( "keep-alive stop tid=$self->{KAID}" );
    $poe_kernel->alarm_remove( delete $self->{KAID} );
}



#######################################
sub timeout_start
{
    my( $self ) = @_;
    return unless $self->{timeout} and $self->{connection};
    if( $self->{TID} ) {
        DEBUG and 
            $self->D1( "timeout restart tid=$self->{TID}" );
        $poe_kernel->delay_adjust( $self->{TID}, $self->{timeout} );
    }
    else {
        DEBUG and $self->D( "timeout timeout=$self->{timeout}" );
        $self->{TID} = $poe_kernel->delay_set( evo( $self->name, "timeout" ), 
                                               $self->{timeout} 
                                             );
        DEBUG and 
            $self->D1( "timeout start tid=$self->{TID}" );
    }
}


#######################################
sub timeout_stop
{
    my( $self ) = @_;
    return unless $self->{TID};
    DEBUG and 
            $self->D1( "timeout stop tid=$self->{TID}" );
    $poe_kernel->alarm_remove( delete $self->{TID} );
}


#######################################
sub shutdown
{
    my( $self ) = @_;
    my $state = $self->state( 'shutdown' );
    DEBUG and $self->D( "shutdown flushing=$self->{flushing} state=$state" );
    $self->{shutdown} = 1;
    $self->{will_close} = 1;
    # If we are handling a request or flushing it's output, we wait
    # until that's completed
    $self->close unless $self->{flushing} or $state eq 'handling';
    $self->keepalive_stop;
}


#######################################
sub pending_push
{
    my( $self, $req ) = @_;
    push @{ $self->{pending} }, $req;
}


#######################################
sub pending_next
{
    my( $self ) = @_;
    return unless $self->{pending} and @{ $self->{pending} };
    if( $self->{S}{shutdown} or $self->{S}{closing} ) {
        $self->D( "We are closing down with pending requests" );
        $self->pending_no_reply;
        return;
    }
    my $next = shift @{ $self->{pending} };
    return unless $next;

    $self->input( $next );
}

#######################################
sub pending_no_reply
{
    my( $self ) = @_;
    return unless $self->{wheel};
    foreach my $req ( @{ $self->{pending} } ) {
        my $resp = $self->build_error_response( RC_SERVICE_UNAVAILABLE, 
                                                "This request could not be handled." );
        $self->{wheel}->put( $resp );
        last unless $self->{wheel}
    }
    $self->{wheel}->flush() if $self->{wheel};
}


##############################################################################
package POEx::HTTP::Server::Session;

use strict;
use warnings;

use POE::Session::PlainCall;
use POE::Session::Multiplex;

use base qw( POE::Session::Multiplex POE::Session::PlainCall );



1;

__END__

=head1 NAME

POEx::HTTP::Server - POE HTTP server

=head1 SYNOPSIS

    use POEx::HTTP::Server;

    POEx::HTTP::Server->spawn( 
                    inet => {
                                LocalPort => 80 
                            },
                    handlers => [
                                '^/$' => 'poe:my-alias/root',
                                '^/static' => 'poe:my-alias/static',
                                '' => 'poe:my-alias/error'
                            ]
                    );
                

    # events of session my-alias:
    sub root {
        my( $heap, $req, $resp ) = @_[HEAP,ARG0,ARG1];
        $resp->content_type( 'text/html' );
        $resp->content( generate_html() );
        $resp->done;
    }

    sub static {
        my( $heap, $req, $resp ) = @_[HEAP,ARG0,ARG1];
        my $file = File::Spec->catfile( $heap->{root}, $req->path );
        $resp->sendfile( $file );
    }

    sub error {
        my( $heap, $req, resp ) = @_[HEAP,ARG0,ARG1];
        $resp->error( 404, "Nothing to do for ".$req->path );
    }


=head1 DESCRIPTION

POEx::HTTP::Server is a clean POE implementation of an HTTP server.  It uses
L<POEx::URI> to simplify event specification.  It allows limiting connection
concurrency and implements HTTP 1.1 keep-alive.  It has built-in
compatibility with L<POE::Component::Daemon> L</prefork> servers.

POEx::HTTP::Server also includes a method for easily sending a static file
to the browser, with automatic support for C<HEAD> and C<If-Modified-Since>.

POEx::HTTP::Server enforces some of the HTTP 1.1 requirements, such as
the C<Content-Length> and C<Date> headers.

POEx::HTTP::Server differs from L<POE::Component::Server::HTTP> by having a
cleaner code base and by being actively maintained.

POEx::HTTP::Server differs from L<POE::Component::Server::SimpleHTTP> by not
using Moose and not using the YELLING-STYLE of parameter passing.



=head1 METHODS

POEx::HTTP::Server has one public class method.

=head2 spawn

    POEx::HTTP::Server->spawn( %CONFIG );

Spawns the server session.  C<%CONFIG> contains one or more of the following
parameters:

=head3 inet

    POEx::HTTP::Server->spawn( inet => $HASHREF );

Specify the parameters handed to L<POE::Wheel::SocketFactory> when creating
the listening socket.

As a convenience, C<LocalAddr> is changed into C<BindAddr> and 
C<LocalPort> into C<BindPort>.


Defaults to:

    POEx::HTTP::Server->spawn( inet => { Listen=>1, BindPort=> 80 } );


=head3 handlers

    POEx::HTTP::Server->spawn( handlers => $HASHREF );
    POEx::HTTP::Server->spawn( handlers => $ARRAYREF );

Set the events that handle a request.  Keys to C<$HASHREF> are regexes which 
match on all or part of the request path.  Values are L<poe: urls|POEx::URI> to
the events that will handle the request.

The regexes are not anchored.  This means that C</foo> will match the path 
C</something/foo>.  Use C<^> if that's what you mean; C<^/foo>.

Specifiying an C<$ARRAYREF> allows you to control the order in which 
the regexes are matched:

    POEx::HTTP::Server->spawn( handlers => [ 
                        'foo'  => 'poe:my-session/foo',
                        'onk'  => 'poe:my-session/onk',
                        'honk' => 'poe:my-session/honk',
                    ] );
    
The handler for C<onk> will always match before C<honk> can.

Use C<''> if you want a catchall handler.

See L</HANDLERS> below.

=head3 handler

    POEx::HTTP::Server->spawn( handler => $uri );

Syntatic sugar for

    POEx::HTTP::Server->spawn( handlers => [ '' => $uri ] );

=head3 alias

    POEx::HTTP::Server->spawn( alias => $ALIAS );
    
Sets the server session's alias.  The alias defaults to 'HTTPd'.

=head3 blocksize

    POEx::HTTP::Server->spawn( blocksize => 5*$MTU );

Sets the block size used when sending a file to the browser.  See
L<POEx::HTTP::Server::Response/sendfile>.  See the L</Note about MTU>.

Default value is 7500 octets, or 5 ethernet fames, assuming the standard
ethernet MTU of 1500 octets.  This is useful for Interanet servers, or talking
to a reverse proxy on the same LAN.

=head3 concurrency

    POEx::HTTP::Server->spawn( concurrency => $NUM );
    
Sets the request concurrency level; this is the number of connections that
are allowed in parallel.  Set to 1 if you want zero concurrency, that is
only one connection at a time.

Be aware that by activating L</keepalive>, a connection may last for many
seconds.  If concurrency is low, this will severly limit the availability of
the server.  If only want one request to be handled at a time, either turn
set keepalive off or use L</prefork>.

Defaults to (-1), unlimited concurrency.

=head3 headers

    POEx::HTTP::Server->spawn( headers => $HASHREF );

All the key/value pairs in C<$HASHREF> will be set as HTTP headers on
all responses.

By default, the C<Server> header is set to C<$PACKAGE/$VERSION> where
C<$PACKAGE> is C<POEx::HTTP::Server> or any sub-class you might have crated
and C<$VERSION> is the current version of C<POEx::HTTP::Server>.

=head3 keepalive

    POEx::HTTP::Server->spawn( keepalive => $N );

Activates the HTTP/1.1 persistent connection feature if true.  Deactivates
keep-alive if false.

Default is 0 (off).

If C<$N> is a number, then it is used as the maximum number of requests
per connection.

If C<$N> isn't a number, or is simply C<1>, then the default is 100.

B<Note> that HTTP/1.0 Keep-Alive extension is currently not supported.

=head3 keepalivetimeout

    POEx::HTTP::Server->spawn( keepalivetimeout => $TIME );

Sets the number of seconds to wait for a request before closing a
connection.  This aplies to the time between completing a request and
receiving a new one.

Defaults to 5 seconds.

=head3 options

    POEx::HTTP::Server->spawn( options => $HASHREF );

Options passed L<POE::Session>->create.  

=head3 prefork

    POEx::HTTP::Server->spawn( prefork => 1 );

Turns on L<POE::Component::Daemon> prefork server support.  You must
spawn and configure the POE::Component::Daemon yourself.  

Defaults to 0, no preforking support.

In a normal preforking server, only one request will be handled by a child
process at the same time.  This is equivalent to L</concurrency> = 1. 
However, you may set concurrecy to another value, so that each child process
may handle several request at the same time.  This has not been tested.

=head3 retry

    POEx::HTTP::Server->spawn( retry => $SECONDS );

If binding to the port fails, the server will wait C<$SECONDS> to retry the 
operation.

Defaults to 60.  Use 0 to turn retry off.

=head3 timeout

    POEx::HTTP::Server->spawn( timeout => $SECONDS );

Set the number of seconds to wait for the next TCP event.  This timeout is
used in the following circumstances :

=over 4

=item *

between accepting a connection and receiving the full request;

=item *

between sending a response and flushing the output buffer; 

=item *

while waiting for a streamed response chunk to flush.

=back

Defaults to 300 seconds.  Setting this timeout to 0 will allow the client to
hold a connection open indefinately.




=head1 HANDLERS

A handler is a POE event that processes a given HTTP request and generates
the response.  It is invoked with:

=over 4

=item C<ARG0> 
: a L<POEx::HTTP::Server::Request> object.  

=item C<ARG1>
: a L<POEx::HTTP::Server::Response> object.

=back

The handler should query the request object for details or parameters of the
request.

    my $req = $_[ARG0];
    my $file = File::Spec->catfile( $doc_root, $req->uri->path );
    
    my $query = $req->uri->query_form;

    my $conn = $req->connection;
    my $ip   = $conn->remote_ip;
    my $port = $conn->remote_port;

The handler must populate the response object with necessary headers and
content.  If the handler wishes to send an error to the browser, it should set
the response code approriately.  A default HTTP status of RC_OK (200) is used.  
The response is sent to the browser with either
C<L<POEx::HTTP::Server::Response/respond>> or
C<L<POEx::HTTP::Server::Response/send>>.  When the handler is finished, it
must call C<L<POEx::HTTP::Server::Response/done>> on the response object.

    # Generated content
    my $resp = $_[ARG1];
    $resp->content_type( 'text/plain' );
    $resp->content( "Hello world\n" );
    $resp->respond;
    $resp->done;

    # HTTP redirect
    use HTTP::Status;
    $resp->code( RC_FOUND );    
    $resp->header( 'Location' => $new_uri );
    $resp->respond;
    $resp->done;

    # Static file
    $resp->content_type( 'text/plain' );
    my $io = IO::File->new( $file );
    while( <$io> ) {
        $resp->send( $_ );
    }
    $resp->done;

The last example is silly.  It would be better to use L</sendfile> like so:

    $resp->content_type( 'image/gif' );
    $resp->sendfile( $file );
    # Don't call ->done after sendfile

Handlers may chain to other event handlers, using normal POE events.  You must
keep track of at least the response handler so that you may call C<done> when
the request is finished.

Here is an example of an unrolled loop:

    sub handler {
        my( $heap, $resp ) = $_[HEAP,ARG1];
        $heap->{todo} = [ qw( one two three ) ];
        $poe_kernel->yield( next_handler => $resp );
    }

    sub next_handler {
        my( $heap, $resp ) = $_[HEAP,ARG0];

        # Get the request object from the response
        my $req = $resp->request;
        # And you can get the connection object from the request

        my $h = shift @{ $heap->{todo} };
        if( $h ) {
            # Send the content returned by event handlers in another session
            my $chunk = $poe_kernel->call( $heap->{session}, $h, $req )
            $resp->send( $chunk );
            $poe_kernel->yield( next_handler => $resp );
        }
        else {
            $poe_kernel->yield( 'last_handler', $resp );
        }
    }

    sub last_handler {
        my( $heap, $resp ) = $_[HEAP,ARG0];
        $resp->done;
    }

    # Event handlers in the other session:
    sub one {
        # ....
        return $chunk;
    }

    sub two {
        # ....
        return $chunk;
    }

    sub three {
        # ....
        return $chunk;
    }


=head2 Handler parameters

POE URIs are allowed to have their own parameter.  If you use them, they
will appear as a hashref in C<ARG0> with the request and response objects as
C<ARG1> and C<ARG2> respectively.

    POEx::HTTP::Server->spawn( handler => 'poe:my-session/handler?honk=bonk' );

    sub handler {
        my( $args, $req, $resp ) = @_[ARG0, ARG1, ARG2];
        # $args = { honk => 'bonk' }
    }


=head2 Handler exceptions

Request handler invocations are wrapped in C<eval{}>.  If the handler throws
an exception with C<die> this will be reported to the browser as a short
message.  Obviously this only applies to the initial request handler.  If
you yield to other POE event handlers, they will not report exceptions to
the browser.


=head2 Special handlers

There are 5 special handlers that are invoked when a browser connection is
opened and closed, before and after each request and when an error occurs.

The note about L</Handler parameters> also aplies to special handlers.

=head3 on_connect

Invoked when a new connection is made to the server.  C<ARG0> is a
L<POEx::HTTP::Server::Connection> object that may be queried for information
about the connection. This connection object will be shared by all requests
objects that use this connection.

    POEx::HTTP::Server->spawn( 
                        handlers => { on_connect => 'poe:my-session/on_connect' }
                     );
    sub on_connect {
        my( $object, $connection ) = @_[OBJECT, ARG0];
        # ...
    }

=head3 on_disconnect

Invoked when a connection is closed. C<ARG0> is the same
L<POEx::HTTP::Server::Connection> object that was passed to L</on_connect>.

=head3 pre_request

Invoked after a request is read from the browser but before it is processed.
C<ARG0> is a L<POEx::HTTP::Server::Request> object.  There is no C<ARG1>.

    POEx::HTTP::Server->spawn( 
                        handlers => { pre_request => 'poe:my-session/pre' }
                     );
    sub pre {
        my( $object, $request ) = @_[OBJECT, ARG0];
        my $connection = $request->connection;
        # ...
    }

If you use L</keepalive>, L</pre_request> will be invoked more often then
C<on_connect>.

=head3 post_request

Invoked after a response has been sent to the browser.  
C<ARG0> is a L<POEx::HTTP::Server::Request> object.  
C<ARG1> is a L<POEx::HTTP::Server::Response> object, with 
it's C<content> cleared.

    POEx::HTTP::Server->spawn( 
                        handlers => { pre_request => 'poe:my-session/post' }
                     );
    sub post {
        my( $self, $request, $response ) = @_[OBJECT, ARG0, ARG1];
        my $connection = $request->connection;
        # ...
    }

=head3 stream_request

Invoked when a chunk has been flushed to the OS, if you are streaming a
response to the browser.  Streaming is turned on with
L<POEx::HTTP::Server::Response/streaming>.

Please remember that while a chunk might be flushed, the OS's network layer
might still decide to combine several chunks into a single packet.  And this
even though we setup a I<hot> socket with C<TCP_NODELAY> set to 1 and
C<SO_SNDBUF> to 576.

=head3 on_error

Invoked when the server detects an error. C<ARG0> is a
L<POEx::HTTP::Server::Error> object.  

There are 2 types of errors: network errors and HTTP errors.  They may be
distiguished by calling the error object's C<op> method.  If C<op> returns
C<undef()>, it is an HTTP error, otherwise a network error.  HTTP errors
already have a message to the browser with HTML content. You may modify the
HTTP error's content and headers before they get sent back to the browser.

Unlike HTTP errors, network errors are never sent to the browser.

    POEx::HTTP::Server->spawn( 
                        handlers => { on_error => 'poe:my-session/error' }
                     );
    sub error {
        my( $self, $err ) = @_[OBJECT, ARG0];
        if( $err->op ) {    # network error
            $self->LOG( $err->op." error [".$err->errnum, "] ".$err->errstr );
            # or the equivalent
            $self->LOG( $err->content );
        }
        else {              # HTTP error
            $self->LOG( $err->status_line );
            $self->content_type( 'text/plain' );
            $self->content( "Don't do that!" );
        }
    }
    
=head1 EVENTS

The following POE events may be used to control POEx::HTTP::Server.

=head2 shutdown

    $poe_kernel->signal( $poe_kernel => 'shutdown' );
    $poe_kernel->post( HTTPd => 'shutdown' );

Initiate server shutdown.  Any pending requests will stay active, however.
The session will exit when the last of the requests has finished. No further
requests will be accepted, even if keepalive is in use.

=head2 handlers_get

    my $handlers = $poe_kernel->call( HTTPd => 'handlers_get' );

Fetch a hashref of handlers and their URIs.  This list contains both the
special handlers and the HTTP handlers.

=head2 handlers_set

    $poe_kernel->post( HTTPD => handlers_set => $URI );
    $poe_kernel->post( HTTPD => handlers_set => $ARRAYREF );
    $poe_kernel->post( HTTPD => handlers_set => $HASHREF );

Change all the handlers at once.  The sole parameter is the same as L</handlers>
passed to L</spawn>.

Note that modifying the set of handlers will only modify the handlers for
new connections, not currently open connections.

=head2 handlers_add

    $poe_kernel->post( HTTPD => handlers_add => $URI );
    $poe_kernel->post( HTTPD => handlers_add => $ARRAYREF );
    $poe_kernel->post( HTTPD => handlers_add => $HASHREF );

Add new handlers to the server, overriding any that might already exist. 
The ordering of handlers is preserved, with all new handlers added to the
end of the list.  The sole parameter is the same as L</handlers>
passed to L</spawn>.

Note that modifying the set of handlers will only modify the handlers for
new connections, not currently open connections.


=head2 handlers_remove

    $poe_kernel->post( HTTPD => handlers_remove => $RE );
    $poe_kernel->post( HTTPD => handlers_remove => $ARRAYREF );
    $poe_kernel->post( HTTPD => handlers_remove => $HASHREF );

Remove one or more handlers from the server.  The handlers are removed based
on the regex, not the handler's URI.  The regex must be exactly identical to
the regex supplied to L</handlers>.

The sole parameter may be :

=head3 $RE

    $poe_kernel->post( HTTPD => handers_remove => '^/static' );

The handler associated with this regex is removed.  

=head3 $ARRAYREF

    $poe_kernel->post( HTTPD => handers_remove => 
                            [ '^/static', '^/static/bigger' ] );

Remove a list of handlers associated.

=head3 $HASHREF

    $poe_kernel->post( HTTPD => handers_remove => 
                            { '^/static' => 1, '^/static/bigger' => 1 } );

The hash's keys are a list of regexes to remove.  The values are ignored.

Note that modifying the set of handlers will not modify the handlers for
currently open connections.



=head1 NOTES

=head2 Sending headers

If you wish to send the headers right away, but send the body later, you may do:

    $resp->header( 'Content-Length' => $size );
    $resp->send;    

The above causes the headers to be sent, allong with any content you might
have added to C<$resp>.

When you want to send the body:

    $resp->send( $content );

When you are finished:

    $resp->done;

=head2 Streaming

Streaming is very similar to sending the headers and body seperately.  See
above.  One difference is that the headers will be flushed and the socket
will be set to I<hot> with TCP_NODELAY and SO_SNBUF.  Another difference is that
keepalive is deactivated for the connection.  Finally difference
is that you will see C<L</stream_request>> when you are allowed to send the
next block. Look for C<L</post_request>> to find out when the last block has
been sent to the browser.

    $resp->streaming( 1 );
    $resp->header( 'Content-Length' => $size );
    $resp->send;

When you want to send a chunk:

    $resp->send( $chunk );

This can be repeated as long as you want.

When you are finished:

    $resp->done;

This will provoke a L</post_request> when the last chunk is flushed.


=head2 blocksize and MTU

If you are using sendfile, but do not have L<Sys::Sendfile> installed you
really should set L</blocksize> to a whole multiple of the interface's MTU. 
Doing so automatically is currently beyond the scope of this module.  Please
see L<Net::Interface/mtu>. But that won't help for servers available over
the the Internet; your local ethernet interface's MTU (1500) is probably
greater then your internet connection's MTU (1400-1492 for DSL).  What's
more, the MTU could be as low as 576.




=head1 SEE ALSO

L<POE>, 
L<POEx::HTTP::Server::Request>,
L<POEx::HTTP::Server::Response>,
L<POEx::HTTP::Server::Error>,
L<POEx::HTTP::Server::Connection>,

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Philip Gwyn.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

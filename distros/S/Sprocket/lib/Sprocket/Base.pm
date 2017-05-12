package Sprocket::Base;

use strict;
use warnings;

use Carp qw( croak );
use Sprocket qw( Common Connection Session AIO );
use POE;

use Class::Accessor::Fast;
use base qw(Class::Accessor::Fast);

our $VERSION = $Sprocket::VERSION;

our $sprocket_aio;
our $sprocket;
our $basic_logger = 'Sprocket::Logger::Basic';

__PACKAGE__->mk_accessors( qw(
    name
    uuid
    _uuid
    shutting_down
    opts
    is_forked
    is_child
    connections
    _logger
    session_id
) );

BEGIN {
    eval "use BSD::Resource";
    eval 'sub HAS_BSD_RESOURCE() { '.( $@ ? 0 : 1 ).' }';

    # can't use $basic_logger here
    eval "use Sprocket::Logger::Basic";
    eval 'sub HAS_BASIC_LOGGER() { '.( $@ ? 0 : 1 ).' }';
    
    $sprocket->register_hook( [qw(
        sprocket.connection.create
        sprocket.connection.destroy
        sprocket.plugin.add
        sprocket.plugin.remove
    )] );
}


# events sent to process_plugins
sub EVENT_NAME() { 0 }
sub SERVER()     { 1 }
sub CONNECTION() { 2 }

our @base_states = qw(
    _start
    _default
    signals
    shutdown
    begin_soft_shutdown
    _log
    events_received
    events_ready
    exception
    process_plugins
    sig_child
    time_out_check
    cleanup
    call_in_ses_context
);

sub spawn {
    my ( $class, $self, @states ) = @_;
    
    # a special session that uses a connection hash
    Sprocket::Session->create(
#       options => { trace => 1 },
        object_states => [
            $self => [ @base_states, @states ]
        ],
    );

    return $self;
}

sub new {
    my $class = shift;
    croak "$class requires an even number of parameters" if @_ % 2;
    my %opts = &adjust_params;
        
    my $uuid = new_uuid();
    
    $opts{alias} = "sprocket/$uuid" unless( defined( $opts{alias} ) and length( $opts{alias} ) );
    $opts{name} = "sprocket/$uuid" unless( defined( $opts{name} ) );
    $opts{time_out} = defined( $opts{time_out} ) ? $opts{time_out} : 30;
    $opts{log_level} = 4 unless( defined( $opts{log_level} ) );
    
    my $logger = delete $opts{logger};
    if ( defined( $logger ) && not UNIVERSAL::can( $logger, 'put' ) ) {
        warn "invalid logger: $logger (no put method), falling back to $basic_logger";
        undef $logger;
    }
    
    unless ( defined $logger ) {
        if ( !HAS_BASIC_LOGGER ) {
            warn "$basic_logger is unavailable.  Logging disabled!";
            undef $logger;
        } else {
            $logger = "$basic_logger"->new(
                parent_alias => $opts{alias},
                log_level => $opts{log_level},
            );
        }
    }
    
    my $self = bless( {
        name => $opts{name},
        opts => \%opts, 
        heaps => {},
        connections => 0,
        plugins => {},
        plugin_pri => [],
        time_out_check => 10, # time_out checker
        type => delete $opts{_type},
        uuid => $uuid,
        is_forked => 0,
        _logger => $logger,
    }, ref $class || $class );

    $self->{_uuid} = gen_uuid( $self );

    $self->check_params if ( $self->can( 'check_params' ) );

    if ( $opts{max_connections} ) {
        if ( HAS_BSD_RESOURCE ) {
            my $ret = setrlimit( RLIMIT_NOFILE, $opts{max_connections}, $opts{max_connections} );
            unless ( defined $ret && $ret ) {
                if ( $> == 0 ) {
                    $self->_log(v => 1, msg => 'Unable to set max connections limit');
                } else {
                    $self->_log(v => 1, msg => 'Need to be root to increase max connections');
                }
            }
        } else {
            $self->_log(v => 1, msg => 'Need BSD::Resource installed to increase max connections');
        }
    }

    $sprocket->add_component( $self );
    
    return $self;
}

sub _start {
    my ( $self, $kernel, $session ) = @_[ OBJECT, KERNEL, SESSION ];

    $self->session_id( $session->ID );
    
    $session->option( @{$self->{opts}->{session_options}} )
        if ( $self->{opts}->{session_options} );
    
    $kernel->alias_set( $self->{opts}->{alias} )
        if ( $self->{opts}->{alias} );


    if ( $self->{opts}->{plugins} ) {
        foreach my $t ( @{ $self->opts->{plugins} } ) {
            # convert CamelCase to camel_case
            $t = adjust_params($t);
            $self->add_plugin(
                $t->{plugin},
                $t->{priority} || 0
            );
        }
    }
    
    if ( my $ev = delete $self->opts->{event_manager} ) {
        eval "use $ev->{module}";
        if ( $@ ) {
            $self->_log(v => 1, msg => "Error loading $ev->{module} : $@");
            $self->shutdown_all;
            return;
        }
        $ev->{options} = []
            unless ( $ev->{options} && ref( $ev->{options} ) eq 'ARRAY' );
        
        $self->{event_manager} = "$ev->{module}"->new(
            @{$ev->{options}},
            parent_id => $self->session_id
        );
    }

    $self->{aio} = defined( $sprocket_aio ) ? 1 : 0;

    $self->{time_out_id} = $kernel->alarm_set( time_out_check => time() + $self->{time_out_check} )
        if ( $self->{time_out_check} );

    # TODO recheck and document
    $kernel->sig( DIE => 'exception' )
        if ( $self->{opts}->{use_exception_handler} );

    $kernel->sig( TSTP => 'signals' )
        unless( $self->opts->{no_tstp} );
    $kernel->sig( INT => 'signals' );

    $kernel->call( $session => '_startup' );
    
    return;
}

sub _default {
    my ( $self, $con, $cmd ) = @_[ OBJECT, HEAP, ARG0 ];
    
    return if ( $cmd =~ m/^_(child|parent)/ );

    return $self->process_plugins( [ $cmd, $self, $con, @_[ ARG1 .. $#_ ] ] )
        if ( UNIVERSAL::can( $con, 'ID' ) );
    
    $self->_log(v => 1, msg => "_default called, no handler for event $cmd"
        ." [$con] (the connection for this event may be gone)");
    
    return;
}

sub signals {
    my ( $self, $signal_name ) = @_[ OBJECT, ARG0 ];

    $self->_log(v => 1, msg => "Client caught SIG$signal_name");

    if ( $signal_name eq 'INT' ) {
        # TODO do something here
        # to stop ctrl-c / INT
        #$_[KERNEL]->sig_handled();
    } elsif ( $signal_name eq 'TSTP' ) {
        local $SIG{TSTP} = 'DEFAULT';
        kill( TSTP => $$ );
        $_[ KERNEL ]->sig_handled();
    }

    return 0;
}

sub sig_child {
    $_[KERNEL]->sig_handled();
}

sub new_connection {
    my $self = shift;
   
    my $con = Sprocket::Connection->new(
        parent_id => $self->session_id,
        @_
    );
    
    # TODO ugh, move this stuff out of here
    $con->event_manager( $self->{event_manager}->{alias} )
        if ( $self->{event_manager} );

    $self->{heaps}->{ $con->ID } = $con;

    my $len = $self->connections( scalar( keys %{$self->{heaps}} ) );

    $sprocket->broadcast( 'sprocket.connection.create', {
        source => $self,
        target => $con,
    } );
    
    return $con;
}

# gets a connection obj from any component
sub get_connection {
    my ( $self, $id, $norec ) = @_;
    
    if ( my $con = $self->{heaps}->{ $id } ) {
        return $con;
    }
    
    return undef if ( $norec );

    return $sprocket->get_connection( $id );
}

sub _log {
    my ( $self, %o ) = ref $_[ KERNEL ] ? @_[ OBJECT, ARG0 .. $#_ ] : @_;
    return unless defined $self->_logger;
    $self->_logger->put( $self, \%o );
}

sub cleanup {
    my ( $self, $con_id ) = @_[ OBJECT, ARG0 ];

    if ( my $con = $self->{heaps}->{ $con_id } ) {
        $self->process_plugins( [ $self->{type}.'_disconnected', $self, $con, 0 ] )
            unless ( defined $con->error );
        $self->cleanup_connection( $con );
    }
}

sub cleanup_connection {
    my ( $self, $con ) = @_;

    return unless( $con );
    
    $sprocket->broadcast( 'sprocket.connection.destroy', {
        source => $self,
        target => $con,
    } );
    
    delete $self->{heaps}->{ $con->ID };
    
    $self->connections( scalar( keys %{$self->{heaps}} ) );

    $self->shutdown()
        if ( $self->shutting_down && $self->connections <= 0 );
    
    return;
}

sub shutdown_all {
    shift;
    $sprocket->shutdown_all( @_ );
}

sub shutdown {
    unless ( $_[KERNEL] && ref $_[KERNEL] ) {
        return $poe_kernel->call( shift->session_id => shutdown => @_ );
    }
    
    my ( $self, $kernel, $type ) = @_[ OBJECT, KERNEL, ARG0 ];

    if ( lc( $type ) eq 'soft' ) {
        $self->shutting_down( $type );
        $kernel->call( $_[SESSION] => 'begin_soft_shutdown' );
        return;
    }

    foreach ( values %{$self->{heaps}} ) {
        $_->close( 1 ); # force
        $self->cleanup_connection( $_ );
    }
    $self->{heaps} = {};

    # XXX proper?
    $kernel->sig( INT => undef );
    $kernel->sig( TSTP => undef );
    $kernel->alarm_remove_all();
    $kernel->alias_remove( $self->{opts}->{alias} )
        if ( $self->{opts}->{alias} );

    # XXX remove plugins one by one?
    delete @{$self}{qw( wheel sf )};

    # if this is the last component, sprocket will shutdown aio
    $sprocket->remove_component( $self );

    return;
}

sub begin_soft_shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    $self->_log(v => 1, msg => $self->{name}." subclass didn't define a begin_soft_shutdown event. shutting down hard!");

    $self->shutdown();

    return;
}

sub events_received {
    my $self = $_[ OBJECT ];
    $self->process_plugins( [ 'events_received', $self, @_[ HEAP, ARG0 .. $#_ ] ] );
}

sub events_ready {
    my $self = $_[ OBJECT ];
    $self->process_plugins( [ 'events_ready', $self, @_[ HEAP, ARG0 .. $#_ ] ] );
}

sub exception {
    my ( $kernel, $self, $con, $sig, $error ) = @_[ KERNEL, OBJECT, HEAP, ARG0, ARG1 ];

    # TODO check exceptions with new POE
    $self->_log(v => 1, l => 1, msg => "plugin exception handled: ($sig) : "
        .join(' | ',map { $_.':'.$error->{$_} } keys %$error ) );
    
    $con->close( 1 ) if ( UNIVERSAL::can( $con, 'close' ) );
    $kernel->sig_handled();
}

sub time_out_check {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    my $time = time();
    $self->{time_out_id} = $kernel->alarm_set( time_out_check => $time + $self->{time_out_check} );

    foreach my $con ( values %{$self->{heaps}} ) {
        next unless ( $con );
        if ( my $timeout = $con->time_out ) {
            $self->process_plugins( [ $self->{type}.'_time_out', $self, $con, $time ] )
                if ( ( $con->active_time + $timeout ) < $time );
        }
    }
}

sub add_plugin {
    my $self = shift;
    
    my $t = $self->{plugins};
   
    my ( $plugin, $pri ) = @_;
    my $uuid;
    
    if ( $plugin->can( 'uuid' ) ) {
        $uuid = $plugin->uuid;
    } else {
        warn "WARNING, plugin $plugin doesn't have a uuid,"
            ."contact the author and have them read the Sprocket::Plugin docs";
        $uuid = "bad-plugin-$plugin";
    }
    
    warn "WARNING : Overwriting existing plugin '$uuid' (You have two plugins with the same id!!)"
        if ( exists( $t->{ $uuid } ) );

    $pri ||= 0;

    my $found = 0;
    foreach ( values %$t ) {
        $found++ if ( $_->{priority} == $pri );
    }
    
    warn "WARNING: You have defined more than one plugin with the same"
        ." priority, was this intended? plugin: $plugin uuid: $uuid pri: $pri"
        if ( $found );

    $t->{ $uuid } = {
        plugin => $plugin,
        priority => $pri,
    };
    
    $plugin->parent_id( $self->session_id );

    $sprocket->broadcast( 'sprocket.plugin.add', {
        source => $self,
        target => $plugin,
    } );
    
    $plugin->handle_event( plugin_start_aio => $self => $pri );
    $plugin->handle_event( add_plugin => $self => $pri );
    
    # recalc plugin order
    @{ $self->{plugin_pri} } = sort {
        $t->{ $a }->{priority} <=> $t->{ $b }->{priority}
    } keys %$t;

    return 1;
}

sub remove_plugin {
    my $self = shift;
    my $uuid = shift;
    
    # TODO remove by name or obj
    
    my $t = $self->{plugins};
    
    my $plugin = delete $t->{ $uuid };
    return 0 unless ( $plugin );
    
    $sprocket->broadcast( 'sprocket.plugin.remove', {
        source => $self,
        target => $plugin,
    } );
    
    $plugin->{plugin}->handle_event( remove_plugin => $plugin->{priority} );
    
    # recalc plugin_pri
    @{ $self->{plugin_pri} } = sort {
        $t->{ $a }->{priority} <=> $t->{ $b }->{priority}
    } keys %$t;
    
    return 1;
}

sub process_plugins {
    my ( $self, $args, $i ) = $_[ KERNEL ] ? @_[ OBJECT, ARG0, ARG1 ] : @_;

    return unless ( @{ $self->{plugin_pri} } );
   
    my $con = $args->[ CONNECTION ];
    $con->state( $args->[ EVENT_NAME ] )
        if ( UNIVERSAL::can( $con, 'state' ) );
    
    if ( UNIVERSAL::can( $con, 'plugin' ) && ( my $t = $con->plugin ) ) {
        return $self->{plugins}->{ $t }->{plugin}->handle_event( @$args );
    } else {
        $i ||= 0;
        if ( $#{ $self->{plugin_pri} } >= $i ) {
            return if ( $self->{plugins}->{
                $self->{plugin_pri}->[ $i ]
            }->{plugin}->handle_event( @$args ) );
        }
        $i++;
        # avoid a post
        return if ( $#{ $self->{plugin_pri} } < $i );
    }
    
    # XXX call?
    #$poe_kernel->call( $self->session_id => process_plugins => $args => $i );
    $poe_kernel->yield( process_plugins => $args => $i );
}

sub get_plugin {
    my ( $self, $uuid ) = @_;

    return $self->{plugins}->{ $uuid }->{plugin}
        if ( exists( $self->{plugins}->{ $uuid } ) );

    # fall back to finding the plugin globally
    return $sprocket->get_plugin( $uuid );
}

sub resolve_plugin_uuid {
    my ( $self, $name ) = @_;

    my $plugin = grep { $name eq $_->{plugin}->name } values %{ $self->{plugins} };

    return $plugin ? $plugin->uuid : undef;
}

sub forward_plugin_by_uuid {
    my $self = shift;
    my $uuid = shift;

    unless( exists ( $self->{plugins}->{ $uuid } ) ) {
        $self->_log( v => 4, msg => 'plugin not loaded! plugin uuid: '.$uuid );
        return 0;
    }
    
    # XXX 
    my $con = $self->{heap};
    $con->plugin( $uuid );

    return $self->process_plugins( [ $con->state, $self, $con, @_ ] );
}
    
sub forward_plugin {
    my $self = shift;
    my $name = shift;

    my ($plugin) = grep { $name eq $_->{plugin}->name } values %{ $self->{plugins} };
    
    unless( $plugin ) {
        $self->_log( v => 4, msg => 'plugin not loaded! plugin: '.$name );
        return 0;
    }

    # XXX 
    my $con = $self->{heap};
    $con->plugin( $plugin->{plugin}->uuid );

    return $self->process_plugins( [ $con->state, $self, $con, @_ ] );
}

# helper used by Sprocket::Connection
sub call_in_ses_context {
    # must call in this in our session's context
    unless ( $_[KERNEL] && ref $_[KERNEL] ) {
        return $poe_kernel->call( shift->session_id => @_ );
    }
    
    my $event = $_[ ARG0 ];
    return $_[ KERNEL ]->$event( @_[ ARG1 .. $#_ ] );
}

1;

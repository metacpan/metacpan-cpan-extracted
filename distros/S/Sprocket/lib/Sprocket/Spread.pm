package Sprocket::Spread;

use strict;
use warnings;

use Sprocket qw( ChannelManager );
use POE qw( Driver::SysRW  Wheel::ReadWrite );
use Spread;
use Carp qw( croak );
use Symbol qw( gensym );

# XXX
use Data::Dumper;

our $sprocket_spread;


sub import {
    my ( $class, $args ) = @_;
    my $package = caller();

    croak "Sprocket::Spread expects its arguments in a hash ref"
        if ( $args && ref( $args ) ne 'HASH' );

    unless ( delete $args->{no_auto_export} ) {
        {
            no strict 'refs';
            *{ $package . '::sprocket_spread' } = \$sprocket_spread;
            # XXX push Spread consts into their namespace?
        }
    }

    return if ( delete $args->{no_auto_bootstrap} );

    # bootstrap
    __PACKAGE__->new( %$args );
    
    return;
}


sub new {
    my $class = shift;
    return $sprocket_spread if ( $sprocket_spread );

    my %args = &adjust_params;
    
    my $host = delete $args{host};
    my $port = delete $args{port};

    warn 'Unknown params passed to Sprocket::Spread: '.join(',', keys %args)."\n"
        if ( keys %args );

    $sprocket_spread = bless( {
        host    => $host,
        port    => $port,
        cm      => Sprocket::ChannelManager->new(),
    }, ref $class || $class);
    
    $sprocket_spread->{session_id} = 
    POE::Session->create(
        object_states => [
            $sprocket_spread => [qw(
                _start
                _stop

                input
                error

                disconnect
                connect
            )]
        ]
    )->ID();

    return $sprocket_spread;
}


sub connect {
    my ( $self, %args );
    if ( ref $_[ KERNEL ] ) {
        ( $self, %args ) = @_[ OBJECT, ARG0 .. $#_ ];
    } else {
        $self = shift;
        return $poe_kernel->call( $self->{session_id} => 'connect' => @_ );
    }
    
    return 1 if ( $self->{connected} );
    
    $args{host} = $self->{host}
        if ( $self->{host} && !$args{host} );
   
    $args{port} = $self->{port}
        if ( $self->{port} && !$args{port} );
        
    $self->{spread_name} = ( $args{port} || '4803' ) . '@' . ( $args{host} || 'localhost' );
    $self->{private_name} = 'sp-' . $$;
    # names can't be too long, because it chops it and finds that the first part is not unique
    # ARGGG!
    #$self->{private_name} = $poe_kernel->ID();

    @{$self}{qw( mbox private_group )} = Spread::connect( {
        spread_name => $self->{spread_name},
        private_name => $self->{private_name},
    } );

    if ( $@ || !defined( $self->{mbox} ) || !defined( $self->{private_group} ) ) {
        warn "Spread connect failed: $@\n";

        $self->{connected} = 0;
        return 0;
    } else {
        # XXX retry?
        my $fh = $self->{fh} = gensym();
        open( $fh, "<&=$self->{mbox}" ) or die $!;

        $self->{wheel} = POE::Wheel::ReadWrite->new(
            Handle      => $fh,
            Driver      => Sprocket::Spread::Driver->new( mbox => $self->{mbox} ),
            Filter      => Sprocket::Spread::Filter->new(),
            InputEvent  => 'input',
            ErrorEvent  => 'error',
        );
        warn "spread connected with mbox: $self->{mbox} priv: $self->{private_name} and spread_name $self->{spread_name}";

        $self->{connected} = 1;
        return 1;
    }

}

sub _start {
    warn "Spread started\n";
    $_[KERNEL]->yield( 'connect' );
}

sub _stop {
    warn "Spread stopped\n";
}

sub error {
    warn "Spread error\n";
    $_[OBJECT]->disconnect();
}

sub input {
    my ( $self, $input ) = @_[ OBJECT, ARG0 ];
    my ( $type, $sender, $groups, $mess_type, $endian, $message ) = @{$input};

    return $self->disconnect()
        unless( defined( $type ) );

    if ( $type & REGULAR_MESS ) {

        if ( defined( $endian ) && $endian ) {
            warn "Spread: endian mismatch!";
        }

        $self->deliver( 'message', $self->{private_name}, {
            type    => 'message',
            message => $message,
            group   => $sender,
            members => $groups,
            index   => $mess_type,
        } );

        return;
    }

    if ( $type & TRANSITION_MESS ) {

        $self->deliver( 'admin', $self->{private_name}, {
            'type' => 'transitional',
            'group' => $sender 
        } );

    } elsif ( $type & CAUSED_BY_LEAVE && !( $type & REG_MEMB_MESS ) ) {

        $self->deliver( 'admin', $self->{private_name}, {
            'type' => 'self_leave',
            'group' => $sender
        } );

    } elsif ( $type & REG_MEMB_MESS ) {

        my ( @gids, $nummem, $member );
        eval {
            @gids = unpack( 'IIIIa*', $message );
            ( $nummem, $member ) = delete @gids[ 3, 4 ];
        };

        if ( $@ ) {
            $self->deliver( 'error', 'receive', $@ );
            return;
        }

        if ( $type & CAUSED_BY_DISCONNECT ) {
            
            $self->deliver( 'admin', $self->{private_name}, {
                type    => 'disconnect',
                who     => $member,
                group   => $sender,
                members => $groups,
                index   => $mess_type,
                gid     => \@gids,
            } );

        } elsif ( $type & CAUSED_BY_NETWORK ) {
            
            $self->deliver( 'admin', $self->{private_name}, {
                type    => 'network',
                message => $message,
                group   => $sender,
                members => $groups,
                index   => $mess_type,
                gid     => \@gids,
            } );

        } elsif ( $type & CAUSED_BY_JOIN ) {
            
            $self->deliver( 'admin', $self->{private_name}, {
                type    => 'join',
                who     => $member,
                group   => $sender,
                members => $groups,
                index   => $mess_type,
                gid     => \@gids,
            } );

        } elsif ( $type & CAUSED_BY_LEAVE ) {

            $self->deliver( 'admin', $self->{private_name}, {
                type    => 'leave',
                who     => $member,
                group   => $sender,
                members => $groups,
                index   => $mess_type,
                gid     => \@gids,
            } );

        } else {
           $self->deliver( 'error', 'receive', 'unknown packet type' );
        }

    } else {
        $self->deliver( 'error', 'receive', 'unknown packet type' );
    }

    return;
}

sub deliver {
    my ( $self, $type ) = ( shift, shift );
    my ( $errtype, $privname, $msg );

    if ( $type eq 'error' ) {
        ( $errtype, $msg ) = @_;
        warn "error: $errtype $msg\n";
    } else {
        ( $privname, $msg ) = @_;
        $self->{cm}->deliver( $type, $privname, $msg );
    }
    
    # XXX
    print STDERR 'msg:'.$privname.' '.Data::Dumper->Dump([$msg]);
    
    return;
}

sub disconnect {
    my ( $self );
    if ( ref $_[ KERNEL ] ) {
        $self = $_[ OBJECT ];
    } else {
        $self = shift;
        return $poe_kernel->call( $self->{session_id} => 'disconnect' => @_ );
    }
    # TODO
    warn "Spread disconnect\n";
    $self->{connected} = 0;
}

sub publish {
    my ( $self, $groups, $message, $mess_type, $flag ) = @_;

    unless ( $self->{mbox} ) {
        warn "not connected when trying to publish to spread";
        return;
    }

    $flag = SAFE_MESS unless( defined( $flag ) );
    
    $mess_type = 0 unless( defined( $mess_type ) );

    $groups = $groups->[0]
        if ( ref( $groups ) && ref( $groups ) eq 'ARRAY' && $#{$groups} == 0 );
    
    require Data::Dumper;
    warn "groups:".Data::Dumper->Dump([$groups]);
    
    my $ret;
    eval {
        $ret = Spread::multicast( $self->{mbox}, $flag, $groups, $mess_type, $message );
    };

    if ( $@ || !defined( $ret ) || $ret < 0 ) {
        $self->disconnect()
            if ( defined $sperrno && $sperrno == CONNECTION_CLOSED );
        return 0;
    }

    return 1;
}

sub subscribe {
    my ( $self, $groups ) = @_;

    unless ( $self->{connected} ) {
        unless ( $self->connect() ) {
            return 0;
        }
    }

    $groups = $groups->[0]
        if ( ref( $groups ) && ref( $groups ) eq 'ARRAY' && $#{$groups} == 0 );

    my $ret;
    eval {
        $ret = Spread::join( $self->{mbox}, $groups );
    };
    if ( $@ && !$ret ) {
        $self->disconnect()
            if ( defined $sperrno && $sperrno == CONNECTION_CLOSED );
        return 0;
    }
    
    return 1;
}

sub unsubscribe {
    my ( $self, $groups ) = @_;

    unless ( $self->{connected} ) {
        unless ( $self->connect() ) {
            return 0;
        }
    }

    $groups = $groups->[0]
        if ( ref( $groups ) && ref( $groups ) eq 'ARRAY' && $#{$groups} == 0 );

    my $ret;
    eval {
        $ret = Spread::leave( $self->{mbox}, $groups );
    };
    if ( $@ && !$ret ) {
        $self->disconnect()
            if ( defined $sperrno && $sperrno == CONNECTION_CLOSED );
        return 0;
    }

    return 1;
}

sub plugin_subscribe {
    my ( $self, $plugin, $groups ) = @_;
    
    return $self->subscribe( $self->{cm}->subscribe( $plugin, $groups ) );
}

sub plugin_unsubscribe {
    my ( $self, $plugin, $groups ) = @_;
    
    return $self->unsubscribe( $self->{cm}->unsubscribe( $plugin, $groups ) );
}

sub plugin_publish {
    my ( $self, $plugin, $groups ) = ( shift, shift, shift );
    
    my $pub = $self->{cm}->grouplist( $plugin, $groups );
    require Data::Dumper;
    warn "plugin publish: $pub ".Data::Dumper->Dump([$pub]);
    return $self->publish( $pub, @_ );
}


1;


package Sprocket::Spread::Driver;

use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;

    my $mbox = delete $args{mbox};

    warn "bad Spread param: ".join( ',', keys %args ) if ( keys %args );

    bless( [ $mbox ], ref $class || $class );
}


sub get {
    my ( $self, $fh ) = @_;

    my ( $type, $sender, $groups, $messt, $endian, $message ) = Spread::receive( $self->[ 0 ] );

    if ( !defined( $type ) ) {
        warn "Spread: Unknown error";
        return [];
    }

    return [ $type, $sender, $groups, $messt, $endian, $message ];
}

1;

package Sprocket::Spread::Filter;

use strict;
use warnings;

sub new {
    my $class = shift;

    bless( [], ref $class || $class );
}

sub get {
    shift;
    return [ @_ ];
}

1;


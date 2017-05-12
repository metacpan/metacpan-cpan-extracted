package Sprocket;

use strict;
use warnings;

our $VERSION = '0.07';

use Carp qw( croak );
use Sprocket::Common;
use POE;

our $sprocket;
our $sprocket_aio;

use Sprocket::AIO;
use Scalar::Util qw( weaken );

use Sprocket::Util::Observable;
use base qw( Sprocket::Util::Observable );

# weak list of all sprocket components
our %COMPONENTS;
our %PLUGINS;

# events sent to process_plugins
sub EVENT_NAME() { 0 }
sub SERVER()     { 1 }
sub CONNECTION() { 2 }


sub import {
    shift;

    my @modules = @_;

    unshift( @modules, 'Common' );
    @modules = map { 'Sprocket::'.$_  } @modules;
   
    unshift( @modules, 'POE' );

    my $package = caller();
    my @failed;

    foreach my $module ( @modules ) {
        my $code = "package $package; use $module;";
        eval( $code );
        if ( $@ ) {
            warn $@;
            push( @failed, $module );
        }
    }

    unless ( defined( $sprocket ) ) {
        Sprocket->new();
    }

    {
        no strict 'refs';
        *{ $package . '::sprocket' } = \$sprocket;
    }

    @failed and croak 'could not import (' . join( ' ', @failed ) . ')';
}

sub new {
    my $class = shift;
    croak "$class requires an even number of parameters" if @_ % 2;
    return $sprocket if ( defined( $sprocket ) );

    my $self = $sprocket = $class->SUPER::new( @_ );
    $self->{_uuid} = gen_uuid( $self );
        
    $self->register_hook( [qw(
        sprocket.component.add
        sprocket.component.remove
        sprocket.plugin.add
        sprocket.plugin.remove
        sprocket.shutdown
    )] );

    return $self;
}

sub add_plugin {
    my $self = shift;
    my $uuid = $_[ 0 ]->uuid;
    
    $PLUGINS{ $uuid } = $_[ 0 ];
    weaken( $PLUGINS{ $uuid } );
    
    $self->broadcast( 'sprocket.plugin.add', {
        source => $self,
        target => $_[ 0 ],
    } );
    
    return;
}

sub remove_plugin {
    my ( $self, $uuid ) = @_;

    $self->broadcast( 'sprocket.plugin.remove', {
        source => $self,
        target => $uuid,
    } );
    
    # supplied the object, get the uuid from it
    $uuid = $uuid->uuid if ( ref( $uuid ) );

    delete $PLUGINS{ $uuid };
    
    return;
}

sub add_component {
    my $self = shift;
    my $uuid = $_[ 0 ]->uuid;
    
    $COMPONENTS{ $uuid } = $_[ 0 ];
    weaken( $COMPONENTS{ $uuid } );
    
    $self->broadcast( 'sprocket.component.add', {
        source => $self,
        target => $_[ 0 ],
    } );
    
    return;
}

sub remove_component {
    my ( $self, $uuid ) = @_;

    $self->broadcast( 'sprocket.component.remove', {
        source => $self,
        target => $uuid,
    } );
    
    $uuid = $uuid->uuid if ( ref( $uuid ) );
    
    my $count = 0;
    delete $COMPONENTS{ $uuid };
    foreach my $id ( keys %COMPONENTS ) {
        next unless defined( $COMPONENTS{ $id } );
        $count++;
    }

    $self->finalize_shutdown() if ( $count == 0 );

    return $count;
}

sub finalize_shutdown {
    my $self = shift;
    
    # this will self elimiate double calls
    return if ( $self->{__SHUTDOWN__}++ );
    
    $sprocket_aio->shutdown()
        if ( $sprocket_aio );

    $self->broadcast( 'sprocket.shutdown', {
        source => $self,
    } );

    $self->clear_hooks();
    
    return;
}

sub get_components {
    # XXX does this make our refs strong again?
    return [ values %COMPONENTS ];
}

sub get_connection {
    my $uuid = $_[ 1 ];

    foreach my $id ( keys %COMPONENTS ) {
        next unless ( defined( $COMPONENTS{ $id } ) );
        if ( my $con = $COMPONENTS{ $id }->get_connection( $uuid, 1 ) ) {
            return $con;
        }
    }

    return undef;
}

sub shutdown_all {
    my $self = shift;
    
    my $count = 0;
    foreach my $id ( keys %COMPONENTS ) {
        next unless ( defined( $COMPONENTS{ $id } ) );
        $COMPONENTS{ $id }->shutdown( @_ );
        $count++;
    }
   
    $self->finalize_shutdown() if ( $count == 0 );
    
    return $count;
}

sub get_plugin {
    my $uuid = $_[ 1 ];
    
    return defined( $PLUGINS{ $uuid } ) ? $PLUGINS{ $uuid } : undef;
}

sub callback {
    my ( $self, $ses, $event, @etc ) = @_;
 
    my $id = $self->_resolve_session( $ses );

    return Sprocket::AnonCallback->new( sub {
        $poe_kernel->call( $id => $event => @etc => @_ );
    }, $id );
}

sub postback {
    my ( $self, $ses, $event, @etc ) = @_;
    
    my $id = $self->_resolve_session( $ses );

    return Sprocket::AnonCallback->new( sub {
        $poe_kernel->post( $id => $event => @etc => @_ );
        return;
    }, $id );
}

sub _resolve_session {
    my ( $self, $ses ) = @_;

    if ( defined( $ses ) && $ses =~ m/^\d+$/ ) {
        return $ses;
    } elsif ( UNIVERSAL::can( $ses, 'ID' ) ) {
        return $ses->ID();
    } else {
        my $s = $poe_kernel->alias_resolve( $ses );
        return $s->ID() if ( $s );
    }
    
    return $poe_kernel->get_active_session()->ID();
}

sub run {
    shift;
    return $poe_kernel->run( @_ );
}

1;

package Sprocket::AnonCallback;

use POE;

our %callback_ids;

sub new {
    my ( $class, $cb, $id ) = @_;
    
    my $self = bless( $cb, ref $class || $class );

    $poe_kernel->refcount_increment(
        $Sprocket::AnonCallback::callback_ids{$self} = $id,
        __PACKAGE__
    );

    return $self;
}

sub DESTROY {
    my $self = shift;
    my $id = delete $Sprocket::AnonCallback::callback_ids{"$self"};

    if ( defined( $id ) ) {
        $poe_kernel->refcount_decrement( $id, __PACKAGE__ );
    } else {
        warn "connection callback DESTROY without session_id to refcount_decrement";
    }

    return;
}

1;

__END__

=pod

=head1 NAME

Sprocket - A pluggable POE based Client / Server Library

=head1 SYNOPSIS

See examples

=head1 ABSTRACT

Sprocket is an POE based networking library that uses plugins similar to POE
Components.

=head1 DESCRIPTION

Sprocket uses a single session for each object/component created to increase speed
and reduce the memory footprint of your apps.  Sprocket is used in the Perl version
of Cometd L<http://cometd.com/>

=head1 NOTES

Sprocket is fully compatable with other POE Compoents.  Apps are normally written as
Sprocket plugins and paired with a L<Sprocket::Server> or L<Sprocket::Client>.

Sprocket's callbacks are different from L<POE::Session>'s callbacks.  The
params are stacked, and not stuffed into two array refs.

Sprocket observer hooks are usable from any module by using Sprocket. 

=head1 METHODS

=over 4

=item shutdown_all( $type )

Shuts down all sprocket components.  $type is optional, and accepts only one
type: 'soft'  This method is short hand for calling shutdown() on every component.
See L<Sprocket::Client>, and L<Sprocket::Server> for shutdown mechanics.

=item callback( $session_id, $event, @etc )

Returns a callback tied to the $session_id. Extra params (@etc) are optional.
For callbacks that are specific to a connection, see L<Sprocket::Connection>

=item postback( $session_id, $event, @etc )

Returns a postback tied to the $session_id. Extra params (@etc) are optional.
For postbacks that are specific to a connection, see L<Sprocket::Connection>

=item register_hook( $hook_name )

Register one or more hooks for the callback system.  You should follow this
convention: 'sprocket.foo.bar.action'  See HOOKS in L<Sprocket::Server>
L<Sprocket::Client>, and below as a template. $hook_name can also be an array
ref of hook names.

=item attach_hook( $hook_name, $callback )

Attach to a callback.  A hook does not need to be registered to be used, but
SHOULD be registered for good style points. :)  $hook_name can also be an array
ref of hook names.  Returns a UUID for this attached set of hooks.

=item remove_hook( $uuid )

Removes one or more attached hooks using the uuid returned by attach_hook.

=item broadcast( $hook_name, $data )

Broadcast a hash ref of $data to observers of $hook_name.  $data will be blessed
into the package L<Sprocket::Event>.  Expect $data to be modified in place.

=item run()

The same as $poe_kernel->run();  See L<POE::Kernel>.

=back

=head1 HOOKS

=over 4

=item sprocket.component.add

=item sprocket.component.remove

=item sprocket.plugin.add

=item sprocket.plugin.remove

=item sprocket.shutdown

=back

=head1 SEE ALSO

L<POE>, L<Sprocket::Connection>, L<Sprocket::Plugin>, L<Sprocket::Server>,
L<Sprocket::Client>, L<Sprocket::AIO>, L<Sprocket::Server::PreFork>,
L<Sprocket::Logger::Basic>, L<Sprocket::Util::Observable>, L<Sprocket::Event>,
L<Sprocket::Util::FDpasser>

L<http://cpantools.com/>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 RATING

Please rate this module.
L<http://cpanratings.perl.org/rate/?distribution=Sprocket>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

Same as Perl, see the LICENSE file.

=cut


package Sprocket::Util::Observable;

use Sprocket::Event;
use Sprocket::Common;

use Scalar::Util qw( reftype );

use strict;
use warnings;

our $observable = {};
our $hooks = {};

sub CALLBACK() { 0 }
sub UUID() { 1 }

sub new {
    my $class = shift;
    
    my $self = bless( { @_ }, ref $class || $class );

    # auto add a cleanup
    ( $self->isa( 'Sprocket' ) ? $self : Sprocket->new() )->attach_hook(
        'sprocket.shutdown',
        sub {
            $self->clear_hooks();
        }
    );
    
    return $self;
}

sub register_hook {
    my $self = shift;
    my $hook_names =_array_ref( shift );

    $observable->{ $_ }++
        foreach ( @$hook_names );
    
    return;
}

sub attach_hook {
    my ( $self, $callback ) = @_[ 0, 2 ];
    my $hook_names =_array_ref( $_[ 1 ] );

    unless ( reftype( $callback ) eq 'CODE' ) {
        # XXX log
        warn "invalid callback: $callback in Sprocket attach_hook, IGNORED!";
        return;
    }

    $hook_names = _array_ref( $hook_names );

    my $uuid = new_uuid();

    $hooks->{ "$self" } = {} unless ( exists( $hooks->{ $self } ) );
    
    foreach ( @$hook_names ) {
        if ( my $list = $hooks->{ $self }->{ $_ } ) {
            push( @$list, [ $callback, $uuid ] );
        } else {
            $hooks->{$self}->{ $_ } = [ [ $callback, $uuid ] ];
        }
    }
    
    return $uuid;
}

sub remove_hook {
    my ( $self, $uuid ) = @_;

    return undef unless ( $hooks->{ $self } );

    foreach ( keys %{$hooks->{ $self }} ) {
        next unless ( $hooks->{ $self }->{ $_ }->[ UUID ] eq $uuid );
        my $h = delete $hooks->{ $self }->{ $_ };
        return $h->[ CALLBACK ];
    }

    return undef;
}

sub broadcast {
    my ( $self, $hook_name, $data ) = @_;
    
    warn "unscheduled broadcast on event hook: $hook_name"
        unless( $observable->{ $hook_name } );
    
    $data = Sprocket::Event->new( $data )
        unless ( UNIVERSAL::isa( $data, 'Sprocket::Event' ) );
    
    $data->hook( $hook_name );

    if ( $hooks->{ $self }->{ $hook_name } ) {
        $_->[ CALLBACK ]->( $data )
            foreach ( @{ $hooks->{ $self }->{ $hook_name } } );
    }
    
    return $data;
}

sub clear_hooks {
    my $self = shift;
    delete $hooks->{ $self };
    return;
}

sub _array_ref {
    return ( ref( $_[0] ) eq 'ARRAY' ) ? $_[0] : [ $_[0] ];
}

1;

__END__

=pod

=head1 NAME

Sprocket::Util::Observable - Helper class for the Sprocket event system

=head1 SYNOPSIS

  package MyModule;

  use Sprocket qw( Util::Observable );
  use base qw( Sprocket::Util::Observable );
  
  sub new {
  
    ... snip ...
    
    $self->register_hook( 'sprocket.mymodule.action' );
    
    ... snip ...
    
  }
  
  ... snip ...

  $self->broadcast( 'sprocket.mymodule.action', { ..data.. } );

=head1 DESCRIPTION

This module provides methods to allow callbacks and event broadasting by name.
It is inteded to be subclassed.

=head1 METHODS

=over 4

=item register_hook( $hook_name )

Register one or more hooks for the callback system.   You should follow this 
convention: 'sprocket.foo.bar.action'  $hook_name can also be an array ref of
hook names.

=item attach_hook( $hook_name, $callback )

Attach to a callback.  A hook does not need to be registered to be used, but
SHOULD be registered for good style points. :)  $hook_name can also be an array
ref of hook names.  Returns a UUID for this attached set of hooks.

=item remove_hook( $uuid )

Removes one or more attached hooks using the uuid returned by attach_hook.

=item broadcast( $hook_name, $data )

Broadcast a hash ref of $data to observers of $hook_name.  $data will be
blessed into the package L<Sprocket::Event>.  Expect $data to be modified in
place.

=item clear_hooks()

Clear all hooks. Good for shutting down when used with sprocket callbacks.
This method will be called for you when L<Sprocket> is shutting down.

=back

=head1 SEE ALSO

L<Sprocket>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

See L<Sprocket> for license information.

=cut


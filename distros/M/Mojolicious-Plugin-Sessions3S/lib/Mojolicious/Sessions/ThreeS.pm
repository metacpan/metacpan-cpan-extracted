package Mojolicious::Sessions::ThreeS;
$Mojolicious::Sessions::ThreeS::VERSION = '0.004';
use strict;
use warnings;

use Carp;
use Mojo::Base 'Mojolicious::Sessions';

use Mojolicious::Sessions::ThreeS::State::Cookie;
use Mojolicious::Sessions::ThreeS::SidGen::Simple;

=head1 NAME

Mojolicious::Sessions:ThreeS - A Mojolicious Sessions manager that supports controlling Storage, State and Sid generation.

=head1 SYNOPSIS

You can use this directly when you build your mojolicious App:

 package My::App;
 use Mojo::Base 'Mojolicious';

 use Mojolicious::Sessions:ThreeS;

 sub startup{
   my ($app) = @_;
   ...
   $app->sessions( Mojolicious::Sessions:ThreeS->new({ storage => ... , state => ... , sidgen => ... } ) );
   ...
 }

Or as a plugin, with exactly the same arguments. See L<Mojolicious::Plugin::Sessions3S>.

=cut

has 'storage';
has 'state' => sub{
    return Mojolicious::Sessions::ThreeS::State::Cookie->new();
};
has 'sidgen' => sub{
    return Mojolicious::Sessions::ThreeS::SidGen::Simple->new();
};

=head2 new

Builds an instance of this given the following properties (all optional):

=over

=item storage

An instance of a subclass of L<Mojolicious::Sessions::ThreeS::Storage>. Defaults to C<undef>

When not given, this will consider itself inactive and fallback to the default L<Mojolicious::Sessions> behaviour.

=item state

An instance of a subclass of L<Mojolicious::Sessions::ThreeS::State>. Defaults to
an instance of L<Mojolicious::Sessions::ThreeS::State::Cookie>.

=item sidgen

An Session ID generator, instance of L<Mojolicious::Sessions::ThreeS::SidGen>. Defaults
to an instance of L<Mojolicious::Sessions::ThreeS::SidGen::Simple>.

=back

=cut

sub new{
    my ( $class ) = ( shift );

    my $self = $class->SUPER::new( @_ );

    return $self;
}

=head2 was_set

This was set with explicit store, storage and sid generator.

Usage:

  if ( $this->was_set() ){
     ...
  }

=cut

sub was_set{
    my ($self) = @_;
    return $self->storage() && $self->state();
}

=head2 cookie_domain

From L<Mojolicious::Sessions>. Delegate to the underlying Cookie
based state. Use this only if you know the state object supports cookies.

=cut

sub cookie_domain{
    my ($self, @rest ) = @_;
    unless( $self->was_set() ){ return $self->SUPER::cookie_domain( @rest ); }
    return $self->state->cookie_domain( @rest );
}


=head2 cookie_name

From L<Mojolicious::Sessions>. Delegate to the underlying Cookie
based state. Use this only if you know the state object supports cookies.

=cut

sub cookie_name{
    my ($self, @rest ) = @_;
    unless( $self->was_set() ){ return $self->SUPER::cookie_name( @rest ); }
    return $self->state->cookie_name( @rest );
}

=head2 cookie_path

From L<Mojolicious::Sessions>. Delegate to the underlying Cookie
based state. Use this only if you know the state object supports cookies.

=cut

sub cookie_path{
    my ($self, @rest ) = @_;
    unless( $self->was_set() ){ return $self->SUPER::cookie_path( @rest ); }
    return $self->state->cookie_path( @rest );
}

=head2 secure

From L<Mojolicious::Sessions>. Delegate to the underlying Cookie
based state. Use this only if you know the state object supports cookies.

=cut

sub secure{
    my ($self, @rest ) = @_;
    unless( $self->was_set() ){ return $self->SUPER::secure( @rest ); }
    return $self->state->secure( @rest );
}

=head2 load

Implements load from L<Mojolicious::Sessions>

=cut

sub load{
    my ($self, $controller) = @_;

    unless( $self->was_set() ){ return $self->SUPER::load( $controller ); }

    # Stuff was set, we need to use it.
    my $session_id = $self->state()->get_session_id( $controller );
    unless( $session_id ){
        return;
    }

    my $session = $self->storage->get_session( $session_id );
    unless( $session ){
        return;
    }

    # We just want to set the session in the stash, as required
    # by Mojolicious::Controller::session

    # Expiration management.
    # This is the 'Policy' setting.
    my $expiration = defined( $session->{expiration} ) ? $session->{expiration} : $self->default_expiration();

    # This is the actual date at which the session should expire.
    my $expires = delete $session->{expires};

    if( $expiration &&
            ! $expires ){
        # No expiry time, but there should be one. Delete the session_id and return
        $self->storage()->remove_session_id( $session_id );
        return;
    }
    if( defined $expires && $expires <= time() ){
        # Session as expired.
        $self->storage()->remove_session_id( $session_id );
        return;
    }

    # If the session is empty, we dont want it to be marked active.
    return unless $controller->stash()->{'mojo.active_session'} = scalar( keys %$session );
    # Note that mojo.active_session acts both way. As a number, it indicates that
    # the stored session was not empty at some point. As a key that just 'exists',
    # it prevents subsequent loading of the session in the second call
    # to $c->session();

    # This is the sessing of the session hash in the stash
    $controller->stash()->{'mojo.session'} = $session;
    # And we transfer the flash if anything has flashed something in some previous requests
    # under the key 'new_flash'. See Mojolicious::Controller::flash
    $session->{flash} = delete $session->{new_flash} if $session->{new_flash};
    return;
}

=head2 store

Implements store from L<Mojolicious::Sessions>

=cut

sub store{
    my ($self, $controller) = @_;


    unless( $self->was_set() ){ return $self->SUPER::store( $controller ); }

    # Stuff was set, we need to use it.
    # Grab the session from the stash and see if we should really save it.
    my $stash = $controller->stash();
    my $session = $stash->{'mojo.session'};

    # No session, no storing needed.
    unless( $session ){ return ; }

    unless( keys %$session || $stash->{'mojo.active_session'} ){
        # The session has never contained anything for the whole duration of this
        # request. No need to store
        return;
    }

    my $old_flash = delete $session->{flash};

    if( $stash->{'mojo.static'} ){
        # Mojo is serving a static resource (like a file).
        # This is marked with mojo.static being set on the stash.
        # Behave as if a new_flash was set against the session
        $session->{new_flash} = \%{ $old_flash };
    }

    # Clear the new_flash if it contains nothing
    unless( keys %{ $session->{new_flash} || {} } ){
        delete $session->{new_flash};
    }

    my $session_id = $self->get_session_id( $session ,  $controller );

    if( defined( $session->{'mojox.sessions3s.old_id'} ) ){
        # Session id has changed. Clear the old one.
        $self->storage->remove_session_id( $session->{'mojox.session3s.old_id'} );
    }


    my $expiration = defined( $session->{expiration} ) ? $session->{expiration} : $self->default_expiration();
    my $set_expires = delete $session->{expires};

    if( $expiration || $set_expires ){
        # There is an expiration policy or expires was set explicitely.
        $session->{expires} = $set_expires  || time + $expiration ;
    }

    # Do the standard thing. Store the session.
    $self->storage->store_session( $session_id , $session );
    # And then inject the session id as a client state.
    $self->state->set_session_id( $controller , $session_id , { expires => $session->{expires} } );
}

=head2 get_session_id

Get the current session ID or generate a fresh one and store it in the given session object,
using the given controller.

Usage:

 my $session_id = $this->session_id( $session, $controller );

=cut

sub get_session_id{
    my ($self, $session, $controller ) = @_;
    return $session->{'mojox.sessions3s.id'} ||= $self->sidgen()->generate_sid( $controller );
}


1;


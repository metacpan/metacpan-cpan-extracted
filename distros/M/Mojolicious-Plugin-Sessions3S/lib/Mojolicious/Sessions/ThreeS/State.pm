package Mojolicious::Sessions::ThreeS::State;
$Mojolicious::Sessions::ThreeS::State::VERSION = '0.004';
use Mojo::Base -base;
use Carp;

=head1 NAME

Mojolicious::Sessions::ThreeS::State - Abstract session state manager

=head1 SYNOPSIS

Implement a subclass of this using C<Mojo::Base> and implement
all methods marked as ABSTRACT

=cut

=head2 get_session_id

ABSTRACT

Return the current session_id if such a thing exists. Undef otherwise.

Called by the framework like this:

  if( my $session_id = $this->get_session_id( $controller ) ){
    ...
  }

=cut

sub get_session_id{
    confess("Implement this");
}

=head2 set_session_id

ABSTRACT

Sets the given session_id against the client using the given L<Mojolicious::Controller>

Called by the framework like this:

  $this->set_session_id( $controller, $session_id , \%options );

Options can include:

  expires: an epoch at which to expire the state. Please make your best effort to respect this if present.

=cut

sub set_session_id{
    confess("Implement this");
}

1;

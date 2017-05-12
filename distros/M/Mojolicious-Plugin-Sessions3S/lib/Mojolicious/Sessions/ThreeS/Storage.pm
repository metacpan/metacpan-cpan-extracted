package Mojolicious::Sessions::ThreeS::Storage;
$Mojolicious::Sessions::ThreeS::Storage::VERSION = '0.004';
use Mojo::Base -base;
use Carp;

=head1 NAME

Mojolicious::Sessions::ThreeS::Storage - Abstract session storage base class

=head1 SYNOPSIS

Implement a subclass of this using C<Mojo::Base> and implement
all methods marked as ABSTRACT.

=cut

=head2 get_session

ABSTRACT

Gets the session C<HashRef> from the given Id. Can return undef if the session
is expired or gone.

Called by the framework like this:

 if( my $session = $this->get_session( $session_id ) ){
    ...
 }

=cut

sub get_session{
    confess("Implement this");
}

=head2 store_session

ABSTRACT

Stores the session C<HashRef> against the given ID. Called by the framework like this:

  $this->store_session( $session_id , $session );

Note that the session might contain an C<expires> Epoch time (in seconds). You should
try to implement this expiry yourself to the best of the underlying storage ability.

=cut

sub store_session{
    confess("Implement this");
}

=head2 remove_session_id

ABSTRACT

Removes the session with the given session_id from the storage. This is idem-potent.

Called by the framework like this:

  $this->remove_session_id( $session_id );

=cut

sub remove_session_id{
    confess("Implement this");
}

1;

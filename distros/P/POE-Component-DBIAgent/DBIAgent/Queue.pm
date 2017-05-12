package POE::Component::DBIAgent::Queue;

=head1 NAME

POE::Component::DBIAgent::Queue -- Helper class for managing a
round-robin queue of Po:Co:DBIAgent:Helper's.

=cut

####  originally by Fletch <fletch@phydeaux.org>
####  originally by Fletch <fletch@phydeaux.org>
####  originally by Fletch <fletch@phydeaux.org>
####  See the credits in the AUTHOR section of the POD.

=head1 SYNOPSIS



=head1 DESCRIPTION


=cut

$VERSION = sprintf("%d.%02d", q$Revision: 0.02 $ =~ /(\d+)\.(\d+)/);

use strict;

use Carp qw/ croak carp /;

use Class::MethodMaker
  new_with_init => 'new',
  new_hash_init => 'hash_init',
  list          => [ qw( _queue ) ],
  ;


=head2 Methods

This are the methods we recognize:

=over 4

=item init

init the queue (currently noop)

=cut

sub init {
    my $self = shift;

    return $self;
}


=item add

append argument to the queue

=cut

sub add { $_[0]->_queue_push( $_[1] ) }

=item clear

Clear the queue

=cut

sub clear { $_[0]->_queue_clear }

## Internal use only
## _find_by -- Return indicies in queue for which supplied predicate
##             returns true
##
sub _find_by {
    my( $self, $predicate ) = @_;
    my $queue = $self->_queue;
    my @ret = grep $predicate->( $queue->[ $_ ] ), 0..$#{$queue};
    return wantarray ? @ret : $ret[0];
}

=item find_by_pid

Find the index of helper with specified pid

=cut

sub find_by_pid {
    my( $self, $pid ) = @_;
    return $self->_find_by( sub { $_[0]->PID == $pid } );
}

=item find_by_wheelid

Find the index of helper with specified wheel id

=cut

sub find_by_wheelid {
    my( $self, $wheel_id ) = @_;
    return $self->_find_by( sub { $_[0]->ID == $wheel_id } );
}

## Internal use only
## _remove_by -- Remove first item from the queue for which supplied
##               predicate returns true
##
sub _remove_by {
    my( $self, $predicate ) = @_;
    my $index = ( $self->_find_by( $predicate ) )[0];

    return splice( @{scalar $self->_queue}, $index, 1 ) if defined $index;

    return
}

=item remove_by_pid

Remove helper with specified pid

=cut

sub remove_by_pid {
    my( $self, $pid ) = @_;
    $self->_remove_by( sub { $_[0]->PID == $pid } );
}

=item remove_by_wheelid

Remove helper with specified wheel id

=cut

sub remove_by_wheelid {
    my( $self, $wheel_id ) = @_;
    $self->_remove_by( sub { $_[0]->ID == $wheel_id } );
}

=item next

Get next helper off the head of the queue (and put it back on the end
(round robin))

=cut

sub next {
    my $self = shift;
    my $ret = $self->_queue_shift;
    $self->_queue_push( $ret );
    return $ret
}

=item make_next

Force the helper with the specified wheel id to the head of the queue.

=cut

sub make_next {
    my $self = shift;
    my $id = shift;
    my $ret = $self->remove_by_wheelid( $id );
    $self->_queue_unshift( $ret );
}

=item exit_all

Tell all our helpers to exit gracefully.

=cut

sub exit_all {
    my $self = shift;
    #++ modified command to stop POE::Filter::Reference moaning
    $_->put({query => "EXIT"}) foreach $self->_queue;
}


=item kill_all

Send the specified signal (default SIGTERM) to all helper processes

=cut

sub kill_all {
    my $self = shift;
    my $sig = shift || 'TERM';

    my @helpers = map { $_->PID } $self->_queue;
    if (@helpers) {
	kill $sig => @helpers;
    }

    # Causes @helpers to be empty on subsequent kill_all() calls.  This
    # was here already; I'm just commenting it.
    $self->_queue_clear;

    return
}

=back

=cut

1;

__END__


=head1 AUTHOR

This module has been fine-tuned and packaged by Rob Bloodgood
E<lt>robb@empire2.comE<gt>.  However, most of the code came I<directly>
from Fletch E<lt>fletch@phydeaux.orgE<gt> and adapted for the release
of POE::Component::DBIAgent.  Thank you, Fletch!

However, I own all of the bugs.

This module is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use strict;

package Salvation::Service::State;

use Moose;

use Salvation::Service::View::Stack ();

has 'stopped'	=> ( is => 'rw', isa => 'Bool', default => 0 );

has 'need_to_skip_view'	=> ( is => 'rw', isa => 'Bool', default => 0 );

has 'view_output'	=> ( is => 'rw', isa => 'Salvation::Service::View::Stack|ArrayRef[Salvation::Service::View::Stack]', lazy => 1, default => sub{ [] } );

has 'output'	=> ( is => 'rw', isa => 'Defined', lazy => 1, default => '' );

sub stop
{
	shift -> stopped( 1 );
}

sub resume
{
	shift -> stopped( 0 );
}

sub skip_view
{
	shift -> need_to_skip_view( 1 );
}

sub use_view
{
	shift -> need_to_skip_view( 0 );
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Service state object

=pod

=head1 NAME

Salvation::Service::State - Service state object

=head1 REQUIRES

L<Moose> 

=head1 METHODS

=head2 view_output

 $state -> view_output();

Returns an instance of L<Salvation::Service::View::Stack>, or an ArrayRef if such instances (depending on C<Salvation::Service::View::MULTINODE> value), as it has been returned from the view after it has been processed.

=head2 output

 $state -> output();

Returns a value as it has been set by L<Salvation::Service::OutputProcessor> after its job is done.

=head2 stop

 $state -> stop();

Mark service as stopped. This will interrupt a service on the next state check which occurs often during the execution flow stage changes.

=head2 resume

 $state -> resume();

Remove "stopped" mark from service.

=head2 stopped

 $state -> stopped();

Returns a boolean value indicating whether service is marked as "stopped", or not.

=head2 skip_view

 $state -> skip_view();

Tells service to ignore upcoming view processing. Should be called at stages before view processing actually began.

=head2 use_view

 $state -> use_view();

If the service been told to ignore view processing - cancels such ignorance. Should be called at stages before view processing actually began.

=head2 need_to_skip_view

 $state -> need_to_skip_view();

Returns a boolean value indicating whether service has been told to ignore view processing, or not.

=cut


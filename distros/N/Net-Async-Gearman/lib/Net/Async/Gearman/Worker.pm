#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Net::Async::Gearman::Worker;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw( Net::Async::Gearman Protocol::Gearman::Worker );
Protocol::Gearman::Worker->VERSION( '0.03' ); # job_finished

=head1 NAME

C<Net::Async::Gearman::Worker> - concrete Gearman worker over an L<IO::Async::Stream>

=head1 SYNOPSIS

=head1 DESCRIPTION

This module combines the abstract L<Protocol::Gearman::Worker> with
L<Net::Async::Gearman> to provide an asynchronous concrete Gearman worker
implementation.

=cut

=head1 METHODS

=cut

=head2 $worker->add_function( $name, $code )

Adds a new function to the collection known by the worker. On connection to
the server, it will declare the names of all of these by using the C<can_do>
method.

The code itself will be invoked with a Job object, and is expected to return
a Future that will give the eventual result of the function. It is not
necessary to invoke the C<complete> or C<fail> methods on the Job; that will
be done automatically when the Future becomes ready.

 $f = $code->( $job )

=cut

sub add_function
{
   my $self = shift;
   my ( $name, $code ) = @_;

   $self->gearman_state->{gearman_funcs}{$name} = $code;
}

sub connect
{
   my $self = shift;
   $self->SUPER::connect( @_ )
      ->on_done( sub {
            my $funcs = $self->gearman_state->{gearman_funcs};

            $self->can_do( $_ ) for keys %$funcs;

            $self->start_grab_job;
         });
}

sub job_finished
{
   my $self = shift;

   my $state = $self->gearman_state;

   $self->start_grab_job unless $self->{gearman_grabf};
}

sub start_grab_job
{
   my $self = shift;

   my $state = $self->gearman_state;

   $state->{gearman_grabf} = $self->grab_job
      ->on_done( sub {
         my ( $job ) = @_;

         undef $state->{gearman_grabf};

         my $code = $state->{gearman_funcs}{$job->func};
         my $job_f = $code->( $job );

         my $handle = $job->handle;

         $state->{gearman_jobs}{$handle} = $job_f
            ->on_done( sub { $job->complete( $_[0] ) } )
            ->on_fail( sub { $job->fail() } )
            ->on_ready( sub { delete $state->{gearman_jobs}{$handle} } );
      });
}

=head1 TODO

=over 4

=item *

Consider how much of this code can or should be moved into
L<Protocol::Gearman::Worker> itself.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

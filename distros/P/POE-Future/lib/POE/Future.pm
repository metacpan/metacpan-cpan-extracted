#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package POE::Future;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp;

use base qw( Future );
Future->VERSION( '0.05' ); # to respect subclassing

use POE;

=head1 NAME

C<POE::Future> - use L<Future> with L<POE>

=head1 SYNOPSIS

 use POE::Future;

 my $future = POE::Future->new_delay( 10 )
    ->then_done( "Hello, world!" );

 say $future->get;

=head1 DESCRIPTION

This subclass of L<Future> integrates with L<POE>, allowing the C<await>
method to block until the future is ready. It allows C<POE>-using code to be
written that returns C<Future> instances, so that it can make full use of
C<Future>'s abilities, including L<Future::Utils>, and also that modules using
it can provide a C<Future>-based asynchronous interface of their own.

For a full description on how to use Futures, see the L<Future> documentation.

=cut

=head1 CONSTRUCTORS

=cut

=head2 $f = POE::Future->new

Returns a new leaf future instance, which will allow waiting for its result to
be made available, using the C<await> method.

=cut

=head2 $f = POE::Future->new_delay( $after )

Returns a new leaf future instance which will become ready (with an empty
result) after the specified delay time.

=cut

sub new_delay
{
   my $self = shift->new;
   my ( $after ) = @_;

   $self->{session} = POE::Session->create(
      inline_states => {
         _start => sub { $_[KERNEL]->delay( done => $after ) },
         cancel => sub { $_[KERNEL]->delay( done => ) },
         done   => sub { $self->done },
      },
   );

   $self->on_cancel( sub {
      my ( $self ) = @_;
      POE::Kernel->post( $self->{session}, cancel => );
   });

   return $self;
}

=head2 $f = POE::Future->new_alarm( $at )

Returns a new leaf future instance which will become ready (with an empty
result) at the specified alarm time.

=cut

sub new_alarm
{
   my $self = shift->new;
   my ( $at ) = @_;

   $self->{session} = POE::Session->create(
      inline_states => {
         _start => sub { $_[KERNEL]->alarm( done => $at ) },
         cancel => sub { $_[KERNEL]->alarm( done => ) },
         done   => sub { $self->done },
      },
   );

   $self->on_cancel( sub {
      my ( $self ) = @_;
      POE::Kernel->post( $self->{session}, cancel => );
   });

   return $self;
}

=pod

To create a delay or alarm timer that will fail instead of succeed, us the
C<then_fail> method:

 my $f = POE::Future->new_delay( 20 )
    ->then_fail( "Timeout" );

=cut

sub await
{
   my $self = shift;
   POE::Kernel::run_one_timeslice until $self->is_ready;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

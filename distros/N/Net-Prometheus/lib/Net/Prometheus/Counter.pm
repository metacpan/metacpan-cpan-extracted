#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus::Counter;

use strict;
use warnings;
use base qw( Net::Prometheus::Metric );

our $VERSION = '0.11';

use Carp;

use constant _type => "counter";

__PACKAGE__->MAKE_child_class;

=head1 NAME

C<Net::Prometheus::Counter> - a monotonically-increasing counter metric

=head1 SYNOPSIS

   use Net::Prometheus;

   my $client = Net::Prometheus->new;

   my $counter = $client->new_counter(
      name => "requests",
      help => "Number of received requests",
   );

   sub handle_request
   {
      $counter->inc;
      ...
   }

=head1 DESCRIPTION

This class provides a counter metric - a value that monotonically increases,
usually used to represent occurrences of some event that happens within the
instrumented program. It is a subclass of L<Net::Prometheus::Metric>.

=cut

=head1 CONSTRUCTOR

Instances of this class are not usually constructed directly, but instead via
the L<Net::Prometheus> object that will serve it:

   $counter = $prometheus->new_counter( %args )

This takes the same constructor arguments as documented in
L<Net::Prometheus::Metric>.

=cut

sub new
{
   my $class = shift;

   my $self = $class->SUPER::new( @_ );

   $self->{values} = {};

   $self->inc( 0 ) if !$self->labelcount;

   return $self;
}

=head1 METHODS

=cut

=head2 inc

   $counter->inc( @label_values, $delta )
   $counter->inc( \%labels, $delta )

   $child->inc( $delta )

Increment the current value for the gauge. C<$delta> will default to 1 if not
supplied and must be non-negative.

=cut

__PACKAGE__->MAKE_child_method( 'inc' );
sub _inc_child
{
   my $self = shift;
   my ( $labelkey, $delta ) = @_;
   defined $delta or $delta = 1;
   $delta >= 0 or
      croak "Cannot increment a counter by a negative value";

   $self->{values}{$labelkey} += $delta;
}

sub samples
{
   my $self = shift;

   my $values = $self->{values};

   return map {
      $self->make_sample( undef, $_, $values->{$_} )
   } sort keys %$values;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

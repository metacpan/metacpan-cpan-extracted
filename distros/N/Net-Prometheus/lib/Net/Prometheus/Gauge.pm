#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016,2018 -- leonerd@leonerd.org.uk

package Net::Prometheus::Gauge;

use strict;
use warnings;
use base qw( Net::Prometheus::Metric );

our $VERSION = '0.11';

use Carp;

use constant _type => "gauge";

__PACKAGE__->MAKE_child_class;

=head1 NAME

C<Net::Prometheus::Gauge> - a snapshot value-reporting metric

=head1 SYNOPSIS

   use Net::Prometheus;

   my $client = Net::Prometheus->new;

   my $gauge = $client->new_gauge(
      name => "users",
      help => "Number of current users",
   );

   my %users;
   ...

   $gauge->set( scalar keys %users );

=head1 DESCRIPTION

This class provides a gauge metric - an arbitrary value that observes some
snapshot of state at some instant in time. This is often used to report on the
current usage of resources by the instrumented program, in a way that can
decrease as well as increase. It is a subclass of L<Net::Prometheus::Metric>.

=head2 Value-Reporting Functions

As an alternative to using the C<set> method to update the value of the gauge,
a callback function can be used instead which should return the current value
to report for that gauge. This function is invoked at collection time, meaning
the reported value is up-to-date.

These functions are invoked inline as part of the collection process, so they
should be as small and lightweight as possible. Typical applications involve
reporting the size of an array or hash within the implementation's code.

   $gauge->set_function( sub { scalar @items } );

   $gauge->set_function( sub { scalar keys %things } );

=cut

=head1 CONSTRUCTOR

Instances of this class are not usually constructed directly, but instead via
the L<Net::Prometheus> object that will serve it:

   $gauge = $prometheus->new_gauge( %args )

This takes the same constructor arguments as documented in
L<Net::Prometheus::Metric>.

=cut

sub new
{
   my $class = shift;

   my $self = $class->SUPER::new( @_ );

   $self->{values}    = {};
   $self->{functions} = {};

   $self->inc( 0 ) if !$self->labelcount;

   return $self;
}

=head1 METHODS

=cut

=head2 set

   $gauge->set( @label_values, $value )
   $gauge->set( \%labels, $value )

   $child->set( $value )

Sets the current value for the gauge.

If the gauge has any labels defined, the values for them must be given first.

=cut

__PACKAGE__->MAKE_child_method( 'set' );
sub _set_child
{
   my $self = shift;
   my ( $labelkey, $value ) = @_;

   $self->{values}{$labelkey} = $value;
}

=head2 set_function

   $gauge->set_function( @label_values, $func )
   $gauge->set_function( \%labels, $func )

   $child->set_function( $func )

Sets a value-returning callback function for the gauge. If the gauge is
labeled, each label combination requires its own function.

When invoked, the function will be passed no arguments and is expected to
return a single value

   $value = $func->()

=cut

__PACKAGE__->MAKE_child_method( 'set_function' );
sub _set_function_child
{
   my $self = shift;
   my ( $labelkey, $func ) = @_;

   # Need to store some sort of value so we still iterate on this labelkey
   # during ->samples
   $self->{values}{$labelkey}    = undef;
   $self->{functions}{$labelkey} = $func;
}

=head2 inc

   $gauge->inc( @label_values, $delta )
   $gauge->inc( \%labels, $delta )

   $child->inc( $delta )

Increment the current value for the gauge. C<$delta> will default to 1 if not
supplied.

=cut

__PACKAGE__->MAKE_child_method( 'inc' );
sub _inc_child
{
   my $self = shift;
   my ( $labelkey, $delta ) = @_;
   defined $delta or $delta = 1;

   $self->{values}{$labelkey} += $delta;
}

=head2 dec

   $gauge->dec( @label_values, $delta )
   $gauge->dec( \%labels, $delta )

   $child->dec( $delta )

Decrement the current value for the gauge. C<$delta> will default to 1 if not
supplied.

=cut

__PACKAGE__->MAKE_child_method( 'dec' );
sub _dec_child
{
   my $self = shift;
   my ( $labelkey, $delta ) = @_;
   defined $delta or $delta = 1;

   $self->{values}{$labelkey} -= $delta;
}

sub samples
{
   my $self = shift;

   my $values    = $self->{values};
   my $functions = $self->{functions};

   return map {
      $self->make_sample( undef, $_,
         $functions->{$_} ? $functions->{$_}->() : $values->{$_}
      )
   } sort keys %$values;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

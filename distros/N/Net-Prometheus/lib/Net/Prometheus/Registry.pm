#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

package Net::Prometheus::Registry;

use strict;
use warnings;

use Carp;

=head1 NAME

C<Net::Prometheus::Registry> - a collection of metrics collectors

=head1 DESCRIPTION

This class, or instances of it, acts as a simple storage array for instances
derived from L<Net::Prometheus::Metric>, known as "collectors".

A single global collection is stored by the module, accessible via the class
methods. Additional collections may be made with the constructor and then
accessed by instance methods.

=cut

# These are the global ones
my @COLLECTORS;

=head1 CONSTRUCTOR

=cut

=head2 new

   $registry = Net::Prometheus::Registry->new

Returns a new registry instance.

=cut

sub new
{
   my $class = shift;
   return bless [], $class;
}

=head1 METHODS

=cut

=head2 register

   $collector = Net::Prometheus::Registry->register( $collector )
   $collector = $registry->register( $collector )

Adds a new collector to the registry. The collector instance itself is
returned, for convenience of chaining method calls on it.

=cut

sub register
{
   my $collectors = ( ref $_[0] ) ? $_[0] : \@COLLECTORS;
   my ( undef, $collector ) = @_;

   # TODO: ban duplicate registration
   push @$collectors, $collector;

   return $collector;
}

=head2 unregister

   Net::Prometheus::Registry->unregister( $collector )
   $registry->unregister( $collector )

Removes a previously-registered collector.

=cut

sub unregister
{
   my $collectors = ( ref $_[0] ) ? $_[0] : \@COLLECTORS;
   my ( undef, $collector ) = @_;

   my $found;
   @$collectors = grep {
      not( $_ == $collector and ++$found )
   } @$collectors;

   $found or
      croak "No such collector";
}

=head2 collectors

   @collectors = Net::Prometheus::Registry->collectors
   @collectors = $registry->collectors

Returns a list of the currently-registered collectors.

=cut

sub collectors
{
   my $collectors = ( ref $_[0] ) ? $_[0] : \@COLLECTORS;
   return @$collectors;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

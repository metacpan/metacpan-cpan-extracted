#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2026 -- leonerd@leonerd.org.uk

package Net::Prometheus::Registry 0.15;

use v5.20;
use warnings;

use feature qw( signatures );
no warnings qw( experimental::signatures );

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

=for highlighter language=perl

=cut

=head2 new

   $registry = Net::Prometheus::Registry->new;

Returns a new registry instance.

=cut

sub new ( $class )
{
   return bless [], $class;
}

=head1 METHODS

=cut

=head2 register

   $collector = Net::Prometheus::Registry->register( $collector );
   $collector = $registry->register( $collector );

Adds a new collector to the registry. The collector instance itself is
returned, for convenience of chaining method calls on it.

=cut

sub register ( $self, $collector )
{
   my $collectors = ( ref $self ) ? $self : \@COLLECTORS;

   # TODO: ban duplicate registration
   push @$collectors, $collector;

   return $collector;
}

=head2 unregister

   Net::Prometheus::Registry->unregister( $collector );
   $registry->unregister( $collector );

Removes a previously-registered collector.

=cut

sub unregister ( $self, $collector )
{
   my $collectors = ( ref $self ) ? $self : \@COLLECTORS;

   my $found;
   @$collectors = grep {
      not( $_ == $collector and ++$found )
   } @$collectors;

   $found or
      croak "No such collector";
}

=head2 collectors

   @collectors = Net::Prometheus::Registry->collectors;
   @collectors = $registry->collectors;

Returns a list of the currently-registered collectors.

=cut

sub collectors ( $self )
{
   my $collectors = ( ref $self ) ? $self : \@COLLECTORS;
   return @$collectors;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

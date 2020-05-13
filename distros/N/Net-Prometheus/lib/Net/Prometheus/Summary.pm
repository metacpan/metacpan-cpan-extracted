#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus::Summary;

use strict;
use warnings;
use base qw( Net::Prometheus::Metric );

our $VERSION = '0.11';

use Carp;
use List::Util 1.33 qw( any );

use constant _type => "summary";

__PACKAGE__->MAKE_child_class;

=head1 NAME

C<Net::Prometheus::Summary> - summarise individual numeric observations

=head1 SYNOPSIS

   use Net::Prometheus;
   use Time::HiRes qw( time );

   my $client = Net::Prometheus->new;

   my $summary = $client->new_summary(
      name => "request_seconds",
      help => "Summary request processing time",
   );

   sub handle_request
   {
      my $start = time();

      ...

      $summary->observe( time() - $start );
   }

=head1 DESCRIPTION

This class provides a summary metric - a combination of a running total and a
counter, that can be used to report on total and average values of
observations, usually times. It is a subclass of L<Net::Prometheus::Metric>.

=cut

=head1 CONSTRUCTOR

Instances of this class are not usually constructed directly, but instead via
the L<Net::Prometheus> object that will serve it:

   $summary = $prometheus->new_summary( %args )

This takes the same constructor arguments as documented in
L<Net::Prometheus::Metric>.

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   $opts{labels} and any { $_ eq "quantile" } @{ $opts{labels} } and
      croak "A Summary may not have a label called 'quantile'";

   my $self = $class->SUPER::new( @_ );

   $self->{counts} = {};
   $self->{sums}   = {};

   if( !$self->labelcount ) {
      $self->{counts}{""} = $self->{sums}{""} = 0;
   }

   return $self;
}

=head2 observe

   $summary->observe( @label_values, $value )
   $summary->observe( \%labels, $value )

   $child->observe( $value )

Increment the summary sum by the given value, and the count by 1.

=cut

__PACKAGE__->MAKE_child_method( 'observe' );
sub _observe_child
{
   my $self = shift;
   my ( $labelkey, $value ) = @_;

   $self->{counts}{$labelkey} += 1;
   $self->{sums}  {$labelkey} += $value;
}

sub samples
{
   my $self = shift;

   my $counts = $self->{counts};
   my $sums   = $self->{sums};

   return map {
      $self->make_sample( count => $_, $counts->{$_} ),
      $self->make_sample( sum   => $_, $sums->{$_} )
   } sort keys %$counts;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

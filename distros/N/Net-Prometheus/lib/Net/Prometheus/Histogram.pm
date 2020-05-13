#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2020 -- leonerd@leonerd.org.uk

package Net::Prometheus::Histogram;

use 5.010; # //
use strict;
use warnings;
use base qw( Net::Prometheus::Metric );

our $VERSION = '0.11';

use Carp;
use List::Util 1.33 qw( any );

use constant _type => "histogram";

use constant DEFAULT_BUCKETS => [
                0.005,
   0.01, 0.025, 0.05, 0.075,
   0.1,  0.25,  0.5,  0.75,
   1.0,  2.5,   5.0,  7.5,
   10
];

__PACKAGE__->MAKE_child_class;

=head1 NAME

C<Net::Prometheus::Histogram> - count the distribution of numeric observations

=head1 SYNOPSIS

   use Net::Prometheus;
   use Time::HiRes qw( time );

   my $client = Net::Prometheus->new;

   my $histogram = $client->new_histogram(
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

This class provides a histogram metric - a count of the distribution of
individual numerical observations into distinct buckets. These are usually
reports of times. It is a subclass of L<Net::Prometheus::Metric>.

=cut

=head1 CONSTRUCTOR

Instances of this class are not usually constructed directly, but instead via
the L<Net::Prometheus> object that will serve it:

   $histogram = $prometheus->new_histogram( %args )

This takes the same constructor arguments as documented in
L<Net::Prometheus::Metric>, and additionally the following:

=over

=item buckets => ARRAY

A reference to an ARRAY containing numerical upper bounds for the buckets.

=item bucket_min => NUM

=item bucket_max => NUM

=item buckets_per_decade => ARRAY[ NUM ]

I<Since version 0.10.>

A more flexible alternative to specifying literal bucket sizes. The values
given in C<buckets_per_decade> are repeated, multiplied by various powers of
10 to generate values between C<bucket_min> (or a default of 0.001 if not
supplied) and C<bucket_max> (or a default of 1000 if not supplied).

=back

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   if( !$opts{buckets} and grep { m/^bucket/ } keys %opts ) {
      _gen_buckets( \%opts );
   }

   my $buckets = $opts{buckets} || DEFAULT_BUCKETS;

   $buckets->[$_] > $buckets->[$_-1] or
      croak "Histogram bucket limits must be monotonically-increasing" for 1 .. $#$buckets;

   $opts{labels} and any { $_ eq "le" } @{ $opts{labels} } and
      croak "A Histogram may not have a label called 'le'";

   my $self = $class->SUPER::new( @_ );

   $self->{bounds}       = [ @$buckets ]; # clone it
   $self->{bucketcounts} = {};
   $self->{sums}         = {};

   if( !$self->labelcount ) {
      $self->{bucketcounts}{""} = [ ( 0 ) x ( @$buckets + 1 ) ];
      $self->{sums}{""} = 0;
   }

   return $self;
}

sub _gen_buckets
{
   my ( $opts ) = @_;

   my $min = $opts->{bucket_min} // 1E-3;
   my $max = $opts->{bucket_max} // 1E3;

   my @values_per_decade = @{ $opts->{buckets_per_decade} // [ 1 ] };

   my $power = 0;
   my $value;
   my @buckets;

   while( ( $value = 10 ** $power ) >= $min ) {
      unshift @buckets, map { $_ * $value } @values_per_decade;

      $power--;
   }

   $power = 1;
   while( ( $value = 10 ** $power ) <= $max ) {
      push @buckets, map { $_ * $value } @values_per_decade;

      $power++;
   }

   # Trim overgenerated ends
   @buckets = grep { $min <= $_ and $_ <= $max } @buckets;

   $opts->{buckets} = \@buckets;
}

=head2 bucket_bounds

   @bounds = $histogram->bucket_bounds

Returns the bounding values for each of the buckets, excluding the final
C<+Inf> bucket.

=cut

sub bucket_bounds
{
   my $self = shift;
   return @{ $self->{bounds} };
}

=head2 observe

   $histogram->observe( @label_values, $value )
   $histogram->observe( \%labels, $value )

   $child->observe( $value )

Increment the histogram sum by the given value, and each bucket count by 1
where the value is less than or equal to the bucket upper bound.

=cut

__PACKAGE__->MAKE_child_method( 'observe' );
sub _observe_child
{
   my $self = shift;
   my ( $labelkey, $value ) = @_;

   my $bounds  = $self->{bounds};
   my $buckets = $self->{bucketcounts}{$labelkey} ||= [ ( 0 ) x ( @$bounds + 1 ) ];

   $value <= $bounds->[$_] and $buckets->[$_]++ for 0 .. $#$bounds;
   $buckets->[scalar @$bounds]++;

   $self->{sums}{$labelkey} += $value;
}

sub samples
{
   my $self = shift;

   my $bounds       = $self->{bounds};
   my $bucketcounts = $self->{bucketcounts};
   my $sums         = $self->{sums};

   return map {
      my $labelkey = $_;
      my $buckets = $bucketcounts->{$labelkey};

      $self->make_sample( count => $labelkey, $buckets->[-1] ),
      $self->make_sample( sum   => $labelkey, $sums->{$labelkey} ),
      ( map {
         $self->make_sample( bucket => $labelkey, $buckets->[$_], [ le => $bounds->[$_] ] )
      } 0 .. $#$bounds ),
      $self->make_sample( bucket => $labelkey, $buckets->[-1], [ le => "+Inf" ] );
   } sort keys %$sums;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

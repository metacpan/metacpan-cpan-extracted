#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus::Metric;

use strict;
use warnings;

our $VERSION = '0.11';

use Carp;
our @CARP_NOT = qw( Net::Prometheus );

use Ref::Util qw( is_hashref );

use Net::Prometheus::Types qw( Sample MetricSamples );

use constant CHILDCLASS => "Net::Prometheus::Metric::_Child";

=head1 NAME

C<Net::Prometheus::Metric> - the base class for observed metrics

=head1 DESCRIPTION

This class provides the basic methods shared by the concrete subclasses,

=over 2

=item *

L<Net::Prometheus::Gauge> - a snapshot value-reporting metric

=item *

L<Net::Prometheus::Counter> - a monotonically-increasing counter metric

=item *

L<Net::Prometheus::Summary> - summarise individual numeric observations

=item *

L<Net::Prometheus::Histogram> - count the distribution of numeric observations

=back

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $metric = Net::Prometheus::Metric->new(
      name => $name,
      help => $help,
   )

The constructor is not normally used directly by instrumented code. Instead it
is more common to use one of the C<new_*> methods on the containing
L<Net::Prometheus> client instance so that the new metric is automatically
registered as a collector, and gets exported by the render method.

   $metric = $prometheus->new_counter(
      name => $name,
      help => $help,
   )

In either case, it returns a newly-constructed metric.

Takes the following named arguments:

=over

=item namespace => STR

=item subsystem => STR

Optional strings giving the namespace and subsystem name parts of the variable
name.

=item name => STR

The basename of the exported variable.

=item help => STR

Descriptive help text for the variable.

=item labels => ARRAY of STR

Optional ARRAY reference giving the names of labels for the metric.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   defined $args{name} or
      croak "Required 'name' argument missing";
   defined $args{help} or
      croak "Required 'help' argument missing";

   my $fullname = join "_", grep { defined } $args{namespace}, $args{subsystem}, $args{name};

   my $labellist = $args{labels} || [];

   # See
   #   https://prometheus.io/docs/concepts/data_model/#metric-names-and-labels
   $fullname =~ m/^[a-zA-Z_:][a-zA-Z0-9_:]*$/ or
      croak "Invalid metric name '$fullname'";

   $_ =~ m/^[a-zA-Z_][a-zA-Z0-9_]*$/ or
      croak "Invalid label name '$_'" for @$labellist;
   $_ =~ m/^__/ and
      croak "Label name '$_' is reserved" for @$labellist;

   return bless {
      fullname => $fullname,
      help => $args{help},
      labels => $labellist,
      labelvalues => {},
   }, $class;
}

=head1 METHODS

=cut

=head2 fullname

   $fullname = $metric->fullname

Returns the full name for the metric. This is formed by joining any of the
defined values for C<namespace>, C<subsystem> and C<name> with C<'_'>.

=cut

sub fullname
{
   my $self = shift;
   return $self->{fullname};
}

=head2 labelcount

   $labels = $metric->labelcount

Returns the number of labels defined for this metric.

=cut

sub labelcount
{
   my $self = shift;
   return scalar @{ $self->{labels} };
}

=head2 labels

   $child = $metric->labels( @values )

   $child = $metric->labels( { name => $value, name => $value, ... } )

Returns a child metric to represent the general one with the given set of
labels. The label values may be provided either in a list corresponding to the
list of label names given at construction time, or by name in a single HASH
reference.

The child instance supports the same methods to control the value of the
reported metric as the parent metric object, except that any label values are
already provided.

This object may be cached for efficiency.

=cut

sub labels
{
   my $self = shift;
   my @values = @_;

   if( @values == 1 and is_hashref( $values[0] ) ) {
      my $labels = $self->{labels};
      my $href = $values[0];

      defined $href->{$_} or croak "No value for $_ label given"
         for @$labels;

      @values = @{$href}{ @$labels };
   }

   my $labelcount = $self->labelcount;
   @values >= $labelcount or
      croak "Insufficient values given for labels";
   @values == $labelcount or
      croak "Too many values given for labels";

   length $values[$_] or
      croak "Value for $self->{labels}[$_] may not empty" for 0 .. $#values;

   my $labelkey = join "\x00", map {
      # Encode \x00 or \x01 as \x{01}0 or \x{01}1 in order to escape the \x00
      # but preserve full leixcal ordering
      my $value = $_;
      $value =~ s/\x01/\x011/g;
      $value =~ s/\x00/\x010/g;
      $value;
   } @values;

   $self->{labelvalues}{$labelkey} = \@values;

   return $self->CHILDCLASS->new(
      $self, $labelkey
   );
}

{
   package
      Net::Prometheus::Metric::_Child;

   use constant {
      METRIC   => 0,
      LABELKEY => 1,
   };

   sub new
   {
      my $class = shift;
      my ( $metric, $labelkey ) = @_;
      return bless [ $metric, $labelkey ], $class;
   }

   sub metric   { shift->[METRIC] }
   sub labelkey { shift->[LABELKEY] }
}

# A metaclass method for declaring the child class
sub MAKE_child_class
{
   my $class = shift;

   my $childclass = "${class}::_Child";

   no strict 'refs';

   # The careful ordering of these two lines should make it possible to
   #   further subclass metrics and metric child classes recursively
   @{"${childclass}::ISA"} = $class->CHILDCLASS;
   *{"${class}::CHILDCLASS"} = sub() { $childclass };
}

# A metaclass method for declaring what Metric subclass methods are proxied
#   via child instances
sub MAKE_child_method
{
   my $class = shift;
   my ( $method ) = @_;

   no strict 'refs';
   *{"${class}::${method}"} = sub {
      my $self = shift;
      my @values = splice @_, 0, is_hashref( $_[0] ) ? 1 : $self->labelcount;

      $self->labels( @values )->$method( @_ );
   };

   my $childmethod = "_${method}_child";

   *{"${class}::_Child::${method}"} = sub {
      my $self = shift;
      $self->metric->$childmethod( $self->labelkey, @_ );
   };
}

=head2 make_sample

   $sample = $metric->make_sample( $suffix, $labelkey, $value, $extralabels )

Returns a new L<Net::Prometheus::Types/Sample> structure to represent the
given value, by expanding the opaque C<$labelkey> value into its actual label
names and values and appending the given suffix (which may be an empty string)
to the metric's fullname. If provided, the suffix will be separated by an
underscore C<'_'>. If provided, C<$extralabels> provides more label names and
values to be added to the sample.

=cut

sub make_sample
{
   my $self = shift;
   my ( $suffix, $labelkey, $value, $extralabels ) = @_;

   my $labelnames  = $self->{labels};
   my $labelvalues = $self->{labelvalues}{$labelkey};

   return Sample(
      ( $suffix ? $self->fullname . "_$suffix" : $self->fullname ),
      [ ( map { $labelnames->[$_], $labelvalues->[$_] } 0 .. $#$labelnames ), @{ $extralabels || [] } ],
      $value,
   );
}

sub collect
{
   my $self = shift;

   return MetricSamples(
      $self->fullname, $self->_type, $self->{help},
      [ $self->samples ],
   );
}

=head2 samples

   @samples = $metric->samples

An abstract method in this class, this method is intended to be overridden by
subclasses.

Called during the value collection process, this method should return a list
of L<Net::Prometheus::Types/Sample> instances containing the values to report
from this metric.

=cut

sub samples
{
   croak "Abstract Net::Prometheus::Metric->samples invoked directly";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

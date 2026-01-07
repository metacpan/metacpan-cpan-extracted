#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2026 -- leonerd@leonerd.org.uk

package Net::Prometheus::Metric 0.15;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Carp;
our @CARP_NOT = qw( Net::Prometheus );

use meta 0.009;  # GvCVu bugfix
no warnings 'meta::experimental';

use Ref::Util qw( is_hashref );

use Net::Prometheus::Types qw( Sample MetricSamples );

use constant CHILDCLASS => "Net::Prometheus::Metric::_Child";

=head1 NAME

C<Net::Prometheus::Metric> - the base class for observed metrics

=head1 DESCRIPTION

=for highlighter language=perl

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
   );

The constructor is not normally used directly by instrumented code. Instead it
is more common to use one of the C<new_*> methods on the containing
L<Net::Prometheus> client instance so that the new metric is automatically
registered as a collector, and gets exported by the render method.

   $metric = $prometheus->new_counter(
      name => $name,
      help => $help,
   );

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

sub new ( $class, %args )
{
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

   $fullname = $metric->fullname;

Returns the full name for the metric. This is formed by joining any of the
defined values for C<namespace>, C<subsystem> and C<name> with C<'_'>.

=cut

sub fullname ( $self )
{
   return $self->{fullname};
}

=head2 labelcount

   $labels = $metric->labelcount;

Returns the number of labels defined for this metric.

=cut

sub labelcount ( $self )
{
   return scalar $self->{labels}->@*;
}

=head2 labels

   $child = $metric->labels( @values );

   $child = $metric->labels( { name => $value, name => $value, ... } );

Returns a child metric to represent the general one with the given set of
labels. The label values may be provided either in a list corresponding to the
list of label names given at construction time, or by name in a single HASH
reference.

The child instance supports the same methods to control the value of the
reported metric as the parent metric object, except that any label values are
already provided.

This object may be cached for efficiency.

=cut

sub labels ( $self, @values )
{
   if( @values == 1 and is_hashref( $values[0] ) ) {
      my $labels = $self->{labels};
      my $href = $values[0];

      defined $href->{$_} or croak "No value for $_ label given"
         for @$labels;

      @values = $href->@{ @$labels };
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
      # but preserve full lexical ordering
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

   sub new ( $class, $metric, $labelkey )
   {
      return bless [ $metric, $labelkey ], $class;
   }

   sub metric   ( $self ) { $self->[METRIC] }
   sub labelkey ( $self ) { $self->[LABELKEY] }
}

# A metaclass method for declaring the child class
sub MAKE_child_class ( $class )
{
   # The careful ordering of these two changes should make it possible to
   #   further subclass metrics and metric child classes recursively
   my $childclass_metapkg = meta::get_package( "${class}::_Child" );
   $childclass_metapkg->get_or_add_symbol( '@ISA' )->reference->@* =
      $class->CHILDCLASS;

   my $class_metapkg = meta::get_package( $class );
   $class_metapkg->add_named_sub(
      CHILDCLASS => sub ( $ = undef ) { "${class}::_Child" }
   );

   # All Metric subclasses should support ->remove
   $class->MAKE_child_method( 'remove' );
}

# A metaclass method for declaring what Metric subclass methods are proxied
#   via child instances
sub MAKE_child_method ( $class, $method )
{
   my $class_metapkg = meta::get_package( $class );

   $class_metapkg->add_named_sub( $method => sub ( $self, @args ) {
      my @values = splice @args, 0, is_hashref( $args[0] ) ? 1 : $self->labelcount;

      $self->labels( @values )->$method( @args );
   } );

   my $childclass_metapkg = meta::get_package( "${class}::_Child" );

   my $childmethod = "_${method}_child";
   $childclass_metapkg->add_named_sub( $method => sub ( $self, @args ) {
      $self->metric->$childmethod( $self->labelkey, @args );
   } );
}

=head2 make_sample

   $sample = $metric->make_sample( $suffix, $labelkey, $value, $extralabels );

Returns a new L<Net::Prometheus::Types/Sample> structure to represent the
given value, by expanding the opaque C<$labelkey> value into its actual label
names and values and appending the given suffix (which may be an empty string)
to the metric's fullname. If provided, the suffix will be separated by an
underscore C<'_'>. If provided, C<$extralabels> provides more label names and
values to be added to the sample.

=cut

sub make_sample ( $self, $suffix, $labelkey, $value, $extralabels = undef )
{
   my $labelnames  = $self->{labels};
   my $labelvalues = $self->{labelvalues}{$labelkey};

   return Sample(
      ( $suffix ? $self->fullname . "_$suffix" : $self->fullname ),
      [ ( map { $labelnames->[$_], $labelvalues->[$_] } 0 .. $#$labelnames ), ( $extralabels || [] )->@* ],
      $value,
   );
}

sub collect ( $self, $ )
{
   return MetricSamples(
      $self->fullname, $self->_type, $self->{help},
      [ $self->samples ],
   );
}

=head2 samples

   @samples = $metric->samples;

An abstract method in this class, this method is intended to be overridden by
subclasses.

Called during the value collection process, this method should return a list
of L<Net::Prometheus::Types/Sample> instances containing the values to report
from this metric.

=cut

sub samples ( $self )
{
   croak "Abstract Net::Prometheus::Metric->samples invoked directly";
}

=head2 remove

   $metric->remove( @values );

   $metric->remove( { name => $value, name => $value, ... } );

I<Since version 0.14.>

Removes a single labelset from the metric. This stops it being reported by
future calls to L</samples>.

=cut

# created by MAKE_child_class

=head2 clear

   $metric->clear;

I<Since version 0.14.>

Removes all the labelsets from the metric, resetting it back to an initial
empty state.

=cut

# must be created by each child class
sub clear ( $self )
{
   croak "Abstract Net::Prometheus::Metric->clear invoked directly";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

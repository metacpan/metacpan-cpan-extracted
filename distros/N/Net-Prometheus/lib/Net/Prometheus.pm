#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus;

use strict;
use warnings;

our $VERSION = '0.05';

use Carp;

use List::Util 1.29 qw( pairmap );

use Net::Prometheus::Gauge;
use Net::Prometheus::Counter;
use Net::Prometheus::Summary;
use Net::Prometheus::Histogram;

use Net::Prometheus::ProcessCollector;

use Net::Prometheus::Types qw( MetricSamples );

=head1 NAME

C<Net::Prometheus> - export monitoring metrics for F<prometheus>

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

   use Plack::Builder;

   builder {
      mount "/metrics" => $client->psgi_app;
      ...
   }

=head1 DESCRIPTION

This module provides the ability for a program to collect monitoring metrics
and export them to the F<prometheus.io> monitoring server.

As C<prometheus> will expect to collect the metrics by making an HTTP request,
facilities are provided to yield a L<PSGI> application that the containing
program can embed in its own structure to provide the results, or the
application can generate a plain-text result directly and serve them by its
own means.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $prometheus = Net::Prometheus->new;

Returns a new C<Net::Prometheus> instance.

Takes the following named arguments:

=over

=item disable_process_collector => BOOL

If present and true, this instance will not load the default process collector
from L<Net::Prometheus::ProcessCollector>. If absent or false, such a
collector will be loaded by default. This is usually what you want.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = bless {
      collectors => [],
   }, $class;

   if( not $args{disable_process_collector} and
       my $process_collector = Net::Prometheus::ProcessCollector->new ) {
      $self->register( $process_collector );
   }

   return $self;
}

=head1 METHODS

=cut

=head2 register

   $collector = $prometheus->register( $collector )

Registers a new L<collector|/COLLECTORS> to be collected from by the C<render>
method. The collector instance itself is returned, for convenience.

=cut

sub register
{
   my $self = shift;
   my ( $collector ) = @_;

   # TODO: ban duplicate registration

   push @{ $self->{collectors} }, $collector;

   return $collector;
}

=head2 unregister

   $prometheus->unregister( $collector )

Removes a previously-registered collector.

=cut

sub unregister
{
   my $self = shift;
   my ( $collector ) = @_;

   my $found;
   @{ $self->{collectors} } = grep {
      not( $_ == $collector and $found++ )
   } @{ $self->{collectors} };

   $found or
      croak "No such collector";
}

=head2 new_gauge

   $gauge = $prometheus->new_gauge( %args )

Constructs a new L<Net::Prometheus::Gauge> using the arguments given and
registers it with the exporter. The newly-constructed gauge is returned.

=cut

sub new_gauge
{
   my $self = shift;
   my %args = @_;

   return $self->register( Net::Prometheus::Gauge->new( %args ) );
}

=head2 new_counter

   $counter = $prometheus->new_counter( %args )

Constructs a new L<Net::Prometheus::Counter> using the arguments given and
registers it with the exporter. The newly-constructed counter is returned.

=cut

sub new_counter
{
   my $self = shift;
   my %args = @_;

   return $self->register( Net::Prometheus::Counter->new( %args ) );
}

=head2 new_summary

   $summary = $prometheus->new_summary( %args )

Constructs a new L<Net::Prometheus::Summary> using the arguments given
and registers it with the exporter. The newly-constructed summary is returned.

=cut

sub new_summary
{
   my $self = shift;
   my %args = @_;

   return $self->register( Net::Prometheus::Summary->new( %args ) );
}

=head2 new_histogram

   $histogram = $prometheus->new_histogram( %args )

Constructs a new L<Net::Prometheus::Histogram> using the arguments given
and registers it with the exporter. The newly-constructed histogram is
returned.

=cut

sub new_histogram
{
   my $self = shift;
   my %args = @_;

   return $self->register( Net::Prometheus::Histogram->new( %args ) );
}

=head2 new_metricgroup

   $group = $prometheus->new_metricgroup( %args )

Returns a new Metric Group instance as a convenience for registering multiple
metrics using the same C<namespace> and C<subsystem> arguments. Takes the
following named arguments:

=over

=item namespace => STR

=item subsystem => STR

String values to pass by default into new metrics the group will construct.

=back

Once constructed, the group acts as a proxy to the other C<new_*> methods,
passing in these values as overrides.

   $gauge = $group->new_gauge( ... )
   $counter = $group->new_counter( ... )
   $summary = $group->new_summary( ... )
   $histogram = $group->new_histogram( ... )

=cut

sub new_metricgroup
{
   my $self = shift;
   my ( %args ) = @_;

   return Net::Prometheus::_MetricGroup->new(
      $self, %args
   );
}

=head2 collect

   @metricsamples = $prometheus->collect

Returns a list of L<Net::Prometheus::Types/MetricSamples> obtained from all
of the currently-registered collectors.

=cut

sub collect
{
   my $self = shift;

   my $collectors = $self->{collectors};

   my %samples_by_name;
   foreach my $collector ( @{ $collectors } ) {
      push @{ $samples_by_name{ $_->fullname } }, $_ for $collector->collect;
   }

   return map {
      my @results = @{ $samples_by_name{ $_ } };
      my $first = $results[0];

      @results > 1 ?
         MetricSamples( $first->fullname, $first->type, $first->help,
            [ map { @{ $_->samples } } @results ]
         ) :
         $first;
   } sort keys %samples_by_name;
}

=head2 render

   $str = $prometheus->render

Returns a string in the Prometheus text exposition format containing the
current values of all the registered metrics.

=cut

sub _render_label_value
{
   my ( $v ) = @_;

   $v =~ s/(["\\])/\\$1/g;
   $v =~ s/\n/\\n/g;

   return qq("$v");
}

sub _render_labels
{
   my ( $labels ) = @_;

   return "" if !scalar @$labels;

   return "{" .
      join( ",", pairmap { $a . "=" . _render_label_value( $b ) } @$labels ) .
      "}";
}

sub render
{
   my $self = shift;

   return join "", map {
      my $metricsamples = $_;

      my $fullname = $metricsamples->fullname;

      "# HELP $fullname " . $metricsamples->help . "\n",
      "# TYPE $fullname " . $metricsamples->type . "\n",
      map {
         my $sample = $_;
         sprintf "%s%s %s\n",
            $sample->varname,
            _render_labels( $sample->labels ),
            $sample->value
      } @{ $metricsamples->samples }
   } $self->collect;
}

=head2 psgi_app

   $app = $prometheus->psgi_app

Returns a new L<PSGI> application as a C<CODE> reference. This application
will render the metrics in the Prometheus text exposition format, suitable for
scraping by the Prometheus collector.

This application will respond to any C<GET> request, and reject requests for
any other method.

=cut

sub psgi_app
{
   my $self = shift;

   return sub {
      my $env = shift;
      my $method = $env->{REQUEST_METHOD};

      $method eq "GET" or return [
         405,
         [ "Content-Type" => "text/plain" ],
         [ "Method $method not supported" ],
      ];

      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ $self->render ],
      ];
   };
}

{
   package
      Net::Prometheus::_MetricGroup;

   sub new
   {
      my $class = shift;
      my ( $prometheus, %args ) = @_;
      return bless {
         prometheus => $prometheus,
         namespace  => $args{namespace},
         subsystem  => $args{subsystem},
      }, $class;
   }

   foreach my $method (qw( new_gauge new_counter new_summary new_histogram )) {
      no strict 'refs';
      *$method = sub {
         my $self = shift;
         $self->{prometheus}->$method(
            namespace => $self->{namespace},
            subsystem => $self->{subsystem},
            @_,
         );
      };
   }
}

=head1 COLLECTORS

The toplevel C<Net::Prometheus> object stores a list of "collector" instances,
which are used to generate the values that will be made visible via the
L</render> method. A collector can be any object instance that has a method
called C<collect>, which when invoked is passed no arguments and expected to
return a list of L<Net::Prometheus::Types/MetricSamples> structures.

   @metricsamples = $collector->collect

The L<Net::Prometheus::Metric> class is already a valid collector (and hence,
so too are the individual metric type subclasses). This interface allows the
creation of new custom collector objects, that more directly collect
information to be exported.

=cut

=head1 TODO

=over 8

=item *

Perl-specific variable collector - arena stats?

=item *

Split Registry out from toplevel instance.

=item *

Write some actual example programs.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

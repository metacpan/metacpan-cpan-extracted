#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2026 -- leonerd@leonerd.org.uk

package Net::Prometheus 0.15;

use v5.20;
use warnings;

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use Carp;

use meta 0.008;
no warnings 'meta::experimental';

use List::Util 1.29 qw( pairmap );

use Net::Prometheus::Gauge;
use Net::Prometheus::Counter;
use Net::Prometheus::Summary;
use Net::Prometheus::Histogram;

use Net::Prometheus::Registry;

use Net::Prometheus::ProcessCollector;
use Net::Prometheus::PerlCollector;

use Net::Prometheus::Types qw( MetricSamples );

=head1 NAME

C<Net::Prometheus> - export monitoring metrics for F<prometheus>

=head1 SYNOPSIS

=for highlighter language=perl

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

=head2 Metrics::Any

For more flexibility of metrics reporting, other modules may wish to use
L<Metrics::Any> as an abstraction interface instead of directly using this
API.

By using C<Metrics::Any> instead, the module does not directly depend on
C<Net::Prometheus>, and in addition program ultimately using the module gets
the flexibility to use Prometheus (via L<Metrics::Any::Adapter::Prometheus>)
or use another reporting system via a different adapter.

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
collector will be loaded by default.

=item disable_perl_collector => BOOL

If present and true, this instance will not load perl-specific collector from
L<Net::Prometheus::PerlCollector>. If absent or false this collector is loaded
by default.

These two options are provided for testing purposes, or for specific use-cases
where such features are not required. Usually it's best just to leave these
enabled.

=back

=cut

sub new ( $class, %args )
{
   my $self = bless {
      registry => Net::Prometheus::Registry->new,
   }, $class;

   if( not $args{disable_process_collector} and
       my $process_collector = Net::Prometheus::ProcessCollector->new ) {
      $self->register( $process_collector );
   }

   if( not $args{disable_perl_collector} ) {
      $self->register( Net::Prometheus::PerlCollector->new );
   }

   return $self;
}

=head1 METHODS

=cut

=head2 register

   $collector = $prometheus->register( $collector );

Registers a new L<collector|/COLLECTORS> to be collected from by the C<render>
method. The collector instance itself is returned, for convenience.

=cut

sub register ( $self, $collector )
{
   return $self->{registry}->register( $collector );
}

=head2 unregister

   $prometheus->unregister( $collector );

Removes a previously-registered collector.

=cut

sub unregister ( $self, $collector )
{
   return $self->{registry}->unregister( $collector );
}

=head2 new_gauge

   $gauge = $prometheus->new_gauge( %args );

Constructs a new L<Net::Prometheus::Gauge> using the arguments given and
registers it with the exporter. The newly-constructed gauge is returned.

=cut

sub new_gauge ( $self, %args )
{
   return $self->register( Net::Prometheus::Gauge->new( %args ) );
}

=head2 new_counter

   $counter = $prometheus->new_counter( %args );

Constructs a new L<Net::Prometheus::Counter> using the arguments given and
registers it with the exporter. The newly-constructed counter is returned.

=cut

sub new_counter ( $self, %args )
{
   return $self->register( Net::Prometheus::Counter->new( %args ) );
}

=head2 new_summary

   $summary = $prometheus->new_summary( %args );

Constructs a new L<Net::Prometheus::Summary> using the arguments given
and registers it with the exporter. The newly-constructed summary is returned.

=cut

sub new_summary ( $self, %args )
{
   return $self->register( Net::Prometheus::Summary->new( %args ) );
}

=head2 new_histogram

   $histogram = $prometheus->new_histogram( %args );

Constructs a new L<Net::Prometheus::Histogram> using the arguments given
and registers it with the exporter. The newly-constructed histogram is
returned.

=cut

sub new_histogram ( $self, %args )
{
   return $self->register( Net::Prometheus::Histogram->new( %args ) );
}

=head2 new_metricgroup

   $group = $prometheus->new_metricgroup( %args );

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

   $gauge = $group->new_gauge( ... );
   $counter = $group->new_counter( ... );
   $summary = $group->new_summary( ... );
   $histogram = $group->new_histogram( ... );

=cut

sub new_metricgroup ( $self, %args )
{
   return Net::Prometheus::_MetricGroup->new(
      $self, %args
   );
}

=head2 collect

   @metricsamples = $prometheus->collect( $opts );

Returns a list of L<Net::Prometheus::Types/MetricSamples> obtained from all
of the currently-registered collectors.

=cut

sub collect ( $self, $opts = undef )
{
   $opts //= {};

   my %samples_by_name;
   foreach my $collector ( $self->{registry}->collectors, Net::Prometheus::Registry->collectors ) {
      push $samples_by_name{ $_->fullname }->@*, $_ for $collector->collect( $opts );
   }

   return map {
      my @results = $samples_by_name{ $_ }->@*;
      my $first = $results[0];

      @results > 1 ?
         MetricSamples( $first->fullname, $first->type, $first->help,
            [ map { $_->samples->@* } @results ]
         ) :
         $first;
   } sort keys %samples_by_name;
}

=head2 render

   $str = $prometheus->render;

Returns a string in the Prometheus text exposition format containing the
current values of all the registered metrics.

   $str = $prometheus->render( { options => "for collectors" } );

An optional HASH reference may be provided; if so it will be passed into the
C<collect> method of every registered collector.

Values that are set to C<undef> will be absent from the output (this usually
applies to gauges). Values set to NaN will be rendered as C<NaN>.

=cut

sub _render_label_value ( $v )
{
   $v =~ s/(["\\])/\\$1/g;
   $v =~ s/\n/\\n/g;

   return qq("$v");
}

sub _render_labels ( $labels )
{
   return "" if !scalar @$labels;

   return "{" .
      join( ",", pairmap { $a . "=" . _render_label_value( $b ) } @$labels ) .
      "}";
}

sub render ( $self, $opts = undef )
{
   return join "", map {
      my $metricsamples = $_;

      my $fullname = $metricsamples->fullname;

      my $help = $metricsamples->help;
      $help =~ s/\\/\\\\/g;
      $help =~ s/\n/\\n/g;

      "# HELP $fullname $help\n",
      "# TYPE $fullname " . $metricsamples->type . "\n",
      map {
         my $sample = $_;
         my $value = $sample->value;
         ( defined $value ) ?
            sprintf "%s%s %s\n",
               $sample->varname,
               _render_labels( $sample->labels ),
               ( ( $value != $value ) ? "NaN" : $value ) :
            ();
      } $metricsamples->samples->@*
   } $self->collect( $opts );
}

=head2 handle

   $response = $prometheus->handle( $request );

Given an HTTP request in an L<HTTP::Request> instance, renders the metrics in
response to it and returns an L<HTTP::Response> instance.

This application will respond to any C<GET> request, and reject requests for
any other method. If a query string is present on the URI it will be parsed
for collector options to pass into the L</render> method.

This method is useful for integrating metrics into an existing HTTP server
application which uses these objects. For example:

   my $prometheus = Net::Prometheus->new;

   sub serve_request
   {
      my ( $request ) = @_;

      if( $request->uri->path eq "/metrics" ) {
         return $prometheus->handle( $request );
      }

      ...
   }

=cut

# Some handy pseudomethods to make working on HTTP::Response less painful
my $set_header = sub ( $resp, @args ) {
   $resp->header( @args );
   $resp;
};
my $set_content = sub ( $resp, @args ){
   $resp->content( @args );
   $resp;
};
my $fix_content_length = sub ( $resp ) {
   $resp->content_length or $resp->content_length( length $resp->content );
   $resp;
};

sub handle ( $self, $request )
{
   require HTTP::Response;

   $request->method eq "GET" or return
      HTTP::Response->new( 405 )
         ->$set_header( Content_Type => "text/plain" )
         ->$set_content( "Method " . $request->method . " not supported" )
         ->$fix_content_length;

   my $opts;
   $opts = { $request->uri->query_form } if length $request->uri->query;

   return HTTP::Response->new( 200 )
      ->$set_header( Content_Type => "text/plain; version=0.0.4; charset=utf-8" )
      ->$set_content( $self->render( $opts ) )
      ->$fix_content_length;
}

=head2 psgi_app

   $app = $prometheus->psgi_app;

Returns a new L<PSGI> application as a C<CODE> reference. This application
will render the metrics in the Prometheus text exposition format, suitable for
scraping by the Prometheus collector.

This application will respond to any C<GET> request, and reject requests for
any other method. If a C<QUERY_STRING> is present in the environment it will
be parsed for collector options to pass into the L</render> method.

This method is useful for integrating metrics into an existing HTTP server
application which is uses or is based on PSGI. For example:

   use Plack::Builder;

   my $prometheus = Net::Prometheus::->new;

   builder {
      mount "/metrics" => $prometheus->psgi_app;
      ...
   }

=cut

sub psgi_app ( $self )
{
   require URI;

   return sub ( $env ) {
      my $method = $env->{REQUEST_METHOD};

      $method eq "GET" or return [
         405,
         [ "Content-Type" => "text/plain" ],
         [ "Method $method not supported" ],
      ];

      my $opts;
      if( defined $env->{QUERY_STRING} ) {
         $opts = +{ URI->new( "?$env->{QUERY_STRING}", "http" )->query_form };
      }

      return [
         200,
         [ "Content-Type" => "text/plain; version=0.0.4; charset=utf-8" ],
         [ $self->render( $opts ) ],
      ];
   };
}

=head2 export_to_Future_IO

   $f = $prometheus->export_to_Future_IO( %args );

Performs the necessary steps to create a minimal HTTP server for exporting
metrics over HTTP, by using L<Future::IO> directly. This requires
C<Future::IO> version 0.11 or above, and a containing process that has already
loaded a non-default loop implementation that supports multiple filehandles.

This new server will listen on its own port number for any incoming request,
and will serve metrics regardless of path.

This server is a very small, minimal implementation just sufficient to support
C<prometheus> itself, or simple tools like C<wget>, C<curl> or perhaps a
web-browser for manual inspection. It is not intended to be a fully-featured
HTTP server and certainly does not support many HTTP features at all.

Takes the following named arguments:

=over 4

=item port => INT

Port number on which to listen for incoming HTTP requests.

=back

The returned L<Future> instance will remain pending for the entire lifetime of
the process. If the containing program has nothing else to do it can call the
C<await> method on it, or else combine it with other toplevel event futures it
is using for its own purposes.

=cut

sub export_to_Future_IO ( $self, %args )
{
   require Net::Prometheus::_FutureIO;
   require IO::Socket::IP;

   my $listensock = IO::Socket::IP->new(
      LocalPort => $args{port},
      Type      => Socket::SOCK_STREAM(),
      # TODO: LocalHost
      Listen     => 1,
      ReuseAddr  => 1,
   ) or die "Cannot create listening socket - $@";

   $args{on_listen} and $args{on_listen}->( $listensock );

   return Net::Prometheus::_FutureIO->start( $self, $listensock );
}

=head2 export_to_IO_Async

   $prometheus->export_to_IO_Async( $loop, %args );

Performs the necessary steps to create an HTTP server for exporting metrics
over HTTP via L<IO::Async>. This will involve creating a new
L<Net::Async::HTTP::Server> instance added to the loop.

This new server will listen on its own port number for any incoming request,
and will serve metrics regardless of path.

Note this should only be used in applications that don't otherwise have an
HTTP server, such as self-contained monitoring exporters or exporting metrics
as a side-effect of other activity. For existing HTTP server applications it
is better to integrate with the existing request/response processing of the
application, such as by using the L</handle> or L</psgi_app> methods.

Takes the following named arguments:

=over 4

=item port => INT

Port number on which to listen for incoming HTTP requests.

=back

=cut

sub export_to_IO_Async ( $self, $loop, %args )
{
   require IO::Async::Loop;
   require Net::Async::HTTP::Server;

   $loop //= IO::Async::Loop->new;

   my $httpserver = Net::Async::HTTP::Server->new(
      on_request => sub ( $httpserver, $req ) {
         $req->respond( $self->handle( $req->as_http_request ) );
      },
   );

   $loop->add( $httpserver );

   # Yes this is a blocking call
   $httpserver->listen(
      socktype => "stream",
      service  => $args{port},
   )->get;
}

{
   package
      Net::Prometheus::_MetricGroup;

   sub new ( $class, $prometheus, %args )
   {
      return bless {
         prometheus => $prometheus,
         namespace  => $args{namespace},
         subsystem  => $args{subsystem},
      }, $class;
   }

   my $metapkg = meta::get_this_package;

   foreach my $method (qw( new_gauge new_counter new_summary new_histogram )) {
      $metapkg->add_named_sub( $method => sub ( $self, @args ) {
         $self->{prometheus}->$method(
            namespace => $self->{namespace},
            subsystem => $self->{subsystem},
            @args,
         );
      } );
   }
}

=head1 COLLECTORS

The toplevel C<Net::Prometheus> object stores a list of "collector" instances,
which are used to generate the values that will be made visible via the
L</render> method. A collector can be any object instance that has a method
called C<collect>, which when invoked is passed no arguments and expected to
return a list of L<Net::Prometheus::Types/MetricSamples> structures.

   @metricsamples = $collector->collect( $opts )

The L<Net::Prometheus::Metric> class is already a valid collector (and hence,
so too are the individual metric type subclasses). This interface allows the
creation of new custom collector objects, that more directly collect
information to be exported.

Collectors might choose to behave differently in the presence of some
specifically-named option; typically to provide extra detail not normally
provided (maybe at the expense of extra processing time to calculate it).
Collectors must not complain about the presence of unrecognised options; the
hash is shared among all potential collectors.

=cut

=head1 TODO

=over 8

=item *

Histogram/Summary 'start_timer' support

=item *

Add other C<export_to_*> methods for other event systems and HTTP-serving
frameworks, e.g. L<Mojo>.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

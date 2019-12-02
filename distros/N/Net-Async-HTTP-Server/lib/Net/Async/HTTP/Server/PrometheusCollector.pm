#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::Server::PrometheusCollector;

use strict;
use warnings;

our $VERSION = '0.10';

use Net::Prometheus::Types qw( MetricSamples Sample );

sub new
{
   my $class = shift;

   return bless {}, $class;
}

my %requests_by_method;
my %responses_by_method_code;

my $responses = 0;

sub observe_request
{
   shift;
   my ( $request ) = @_;

   $requests_by_method{ $request->method }++;
}

sub observe_response
{
   shift;
   my ( $request ) = @_;

   $responses_by_method_code{ join "\0", $request->method, $request->response_status_code }++;
}

sub collect
{
   return
      MetricSamples( "net_async_http_server_requests", gauge => "Number of HTTP requests received",
         [ map {
            Sample( "net_async_http_server_requests", [ method => $_ ], $requests_by_method{$_} )
         } sort keys %requests_by_method ] ),
      MetricSamples( "net_async_http_server_responses", gauge => "Number of HTTP responses served",
         [ map {
            my ( $method, $code ) = split m/\0/, $_;
            Sample( "net_async_http_server_responses", [ method => $method, code => $code ], $responses_by_method_code{$_} )
         } sort keys %responses_by_method_code ] ),
}

0x55AA;

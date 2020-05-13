#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

package Net::Prometheus::PerlCollector;

use strict;
use warnings;

BEGIN {
   our $VERSION = '0.11';
}

use constant HAVE_XS => defined eval {
   require XSLoader;
   XSLoader::load( __PACKAGE__, our $VERSION );
   1;
};

use Net::Prometheus::Types qw( MetricSamples Sample );

our $DETAIL = 0;

=head1 NAME

C<Net::Prometheus::PerlCollector> - obtain statistics about the perl interpreter

=head1 SYNOPSIS

   use Net::Prometheus;
   use Net::Prometheus::PerlCollector;

   my $client = Net::Prometheus->new;
   $client->register( Net::Prometheus::PerlCollector->new );

=head1 DESCRIPTION

This module provides a class that collects metrics about the perl interpreter
itself.

=head2 Metrics

The following metrics are collected:

=over 2

=item * C<perl_info>

An info gauge (i.e. whose value is always 1) with a C<version> label giving
the perl interpreter version

   # HELP perl_info Information about the Perl interpreter
   # TYPE perl_info gauge
   perl_info{version="5.30.0"} 1

=back

If the optional XS module was compiled at build time, the following extra are
also reported:

=over 2

=item * C<perl_heap_arenas>

A gauge giving the number of arenas the heap is split into.

=item * C<perl_heap_svs>

A gauge giving the total number of SVs allocated on the heap.

=back

   # HELP perl_heap_arenas Number of arenas in the Perl heap
   # TYPE perl_heap_arenas gauge
   perl_heap_arenas 159
   # HELP perl_heap_svs Number of SVs in the Perl heap
   # TYPE perl_heap_svs gauge
   perl_heap_svs 26732

Note that the way these metrics are collected requires counting them all every
time. While this code is relatively efficient, it is still a linear scan, and
may itself cause some slowdown of the process at the time it is collected, if
the heap has grown very large, containing a great number of SVs.

Extra detail can be obtained about the types of heap objects by setting

   $Net::Prometheus::PerlCollector::DETAIL = 1;

This will be slightly more expensive to count, but will yield in addition a
detailed breakdown by object type.

   # HELP perl_heap_svs_by_type Number of SVs classified by type
   # TYPE perl_heap_svs_by_type gauge
   perl_heap_svs_by_type{type="ARRAY"} 2919
   perl_heap_svs_by_type{type="CODE"} 1735
   perl_heap_svs_by_type{type="GLOB"} 2647
   perl_heap_svs_by_type{type="HASH"} 470
   perl_heap_svs_by_type{type="INVLIST"} 68
   perl_heap_svs_by_type{type="IO"} 12
   perl_heap_svs_by_type{type="NULL"} 8752
   perl_heap_svs_by_type{type="REGEXP"} 171
   perl_heap_svs_by_type{type="SCALAR"} 9958

This level of detail is unlikely to be useful for most generic production
purposes but may be helpful to set in specific processes when investigating
specific memory-related issues for a limited time.

For an even greater level of detail, set the value to 2 to additionally obtain
another breakdown of blessed objects by class:

   # HELP perl_heap_svs_by_class Number of SVs classified by class
   # TYPE perl_heap_svs_by_class gauge
   ...
   perl_heap_svs_by_class{class="Net::Prometheus"} 1
   perl_heap_svs_by_class{class="Net::Prometheus::PerlCollector"} 1
   perl_heap_svs_by_class{class="Net::Prometheus::ProcessCollector::linux"} 1

Note that this will yield a large amount of output for any non-trivially sized
program, so should only be enabled under carefully-controlled conditions.

The value of this variable can be overridden on a per-collection basis by
passing the option

   Net::Prometheus->render( { perl_collector_detail => 1 } );  # or 2

This may be more convenient for short-term traces from exporters that parse
HTTP query parameters into collector options.

   GET .../metrics?perl_collector_detail=1

=cut

sub new
{
   my $class = shift;

   return bless {}, $class;
}

# Might as well keep these as constants
use constant
   PERL_VERSION => ( $^V =~ m/^v(.*)$/ )[0];

sub collect
{
   shift;
   my ( $opts ) = @_;

   local $DETAIL = $opts->{perl_collector_detail} if $opts and exists $opts->{perl_collector_detail};

   my @ret = (
      MetricSamples( "perl_info", gauge => "Information about the Perl interpreter",
         [ Sample( "perl_info", [ version => PERL_VERSION ], 1 ) ] ),
   );

   if( HAVE_XS ) {
      my ( $arenas, $svs, $svs_by_type, $svs_by_class ) = count_heap( $DETAIL );

      push @ret,
         MetricSamples( "perl_heap_arenas", gauge => "Number of arenas in the Perl heap",
            [ Sample( "perl_heap_arenas", [], $arenas ) ] ),
         MetricSamples( "perl_heap_svs", gauge => "Number of SVs in the Perl heap",
            [ Sample( "perl_heap_svs", [], $svs ) ] );

      if( $svs_by_type ) {
         push @ret, MetricSamples( "perl_heap_svs_by_type", gauge => "Number of SVs classified by type",
            [ map { Sample( "perl_heap_svs_by_type", [ type => $_ ], $svs_by_type->{$_} ) } sort keys %$svs_by_type ] );
      }

      if( $svs_by_class ) {
         push @ret, MetricSamples( "perl_heap_svs_by_class", gauge => "Number of SVs classified by class",
            [ map { Sample( "perl_heap_svs_by_class", [ class => $_ ], $svs_by_class->{$_} ) } sort keys %$svs_by_class ] );
      }
   }

   return @ret;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

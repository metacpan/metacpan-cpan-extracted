#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018 -- leonerd@leonerd.org.uk

package Net::Prometheus::PerlCollector;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

use Net::Prometheus::Types qw( MetricSamples Sample );

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

=item * C<perl_heap_arenas>

A gauge giving the number of arenas the heap is split into.

=item * C<perl_heap_svs>

A gauge giving the total number of SVs allocated on the heap.

=back

Note that the way these metrics are collected requires counting them all every
time. While this code is relatively efficient, it is still a linear scan, and
may itself cause some slowdown of the process at the time it is collected, if
the heap has grown very large, containing a great number of SVs.

=cut

sub new
{
   my $class = shift;

   return bless {}, $class;
}

sub collect
{
   my ( $arenas, $svs ) = count_heap();

   return
      MetricSamples( "perl_heap_arenas", gauge => "Number of arenas in the Perl heap",
         [ Sample( "perl_heap_arenas", [], $arenas ) ] ),
      MetricSamples( "perl_heap_svs", gauge => "Number of SVs in the Perl heap",
         [ Sample( "perl_heap_svs", [], $svs ) ] );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

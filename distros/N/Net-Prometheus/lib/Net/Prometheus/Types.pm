#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Net::Prometheus::Types;

use strict;
use warnings;

our $VERSION = '0.11';

use Exporter 'import';
our @EXPORT_OK;

use Struct::Dumb qw( readonly_struct );

=head1 NAME

C<Net::Prometheus::Types> - a collection of support structure types

=head1 SYNOPSIS

   use Net::Prometheus::Types qw( Sample );

   my $ob = Sample( variable => [], 123 );

   print "The sample relates to a variable called ", $ob->varname;

=head1 DESCRIPTION

This package contains some simple support structures that assist with other
parts of the L<Net::Prometheus> distribution.

Each type is exported as a constructor function.

=cut

=head1 TYPES

=cut

=head2 Sample

This structure represents an individual value sample; associating a numerical
value with a named variable and set of label values.

   $sample = Sample( $varname, $labels, $value )

=head3 varname

   $varname = $sample->varname

The string variable name. This is the basic name, undecorated by label values.

=head3 labels

   $labels = $sample->labels

A reference to an even-sized ARRAY containing name/value pairs for the labels.
Label values should be raw unescaped strings.

=head3 value

   $sample->value

The numerical value observed.

=cut

push @EXPORT_OK, qw( Sample );
readonly_struct Sample => [qw( varname labels value )];

=head2 MetricSamples

This structure represents all the samples made about a given metric, including
metadata about the metric itself.

   $samples = MetricSamples( $fullname, $type, $help, $samples )

=head3 fullname

A string giving the fullname of the metric.

=head3 type

A string, one of C<'gauge'>, C<'counter'>, C<'summary'> or C<'histogram'>.

=head3 help

A string containing the descriptive help message text.

=head3 samples

A reference to an ARRAY containing individual L</Sample> instances.

=cut

push @EXPORT_OK, qw( MetricSamples );
readonly_struct MetricSamples => [qw( fullname type help samples )];

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

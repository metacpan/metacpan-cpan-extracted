package Perl::Metrics::Metric;

=pod

=head1 NAME

Perl::Metrics::Metric - A Perl Document Metric

=head1 DESCRIPTION

This class provides objects that represent a single metric on a single
document (although that document might actual exist as a number of
duplicate files in the index).

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, this class has
the following additional methods.

=cut

use strict;
use Perl::Metrics ();
use base 'Perl::Metrics::CDBI';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.09';
}

=pod

=head2 hex_id

In the L<Perl::Metrics> system all documents are identified by the
hexidecimal MD5 value for their newline-localized contents.

The C<hex_id> accessor returns this id for the document that the metric
is for.

=head2 package

The C<package> returns a string which contains the class name of the metrics
package that generated the metric.

=head2 name

The C<name> accessor returns the name of the metric.

This name is package-specific. That is, a metric with a package of
'Foo' and name 'some_metric' is different to a metric with package
'Bar' and the same name 'some_metric'.

The metric name itself must be a valid Perl identifier. This test is
done using the C<_IDENTIFIER> function from L<Params::Util>.

=head2 version

In L<Perl::Metrics> some metrics packages will produce metrics that are
"version-unstable". In other words, if the metrics package is upgraded,
the metrics need to be recalculated.

The C<version> accessor returns the version of the metrics package at the
time the metric was calculated.

=head2 value

The C<value> accessor returns the value of the accessor. This could be
a number, word, or anything else. Please note that a value of C<undef>,
does B<not> mean the lack of a metric, but rather it means "unknown"
or "indeterminate" or has some other signficant meaning (in the context
of the metrics package).

=cut

Perl::Metrics::Metric->table( 'metrics' );
Perl::Metrics::Metric->columns( Primary =>
	'hex_id',  # Document MD5 Identifier    - 'abcdef1234567890'
	'package', # Metrics Package Class Name - 'Perl::Metrics::Plugin::Core'
	'name',    # Package Metric Name        - 'tokens'
	);
Perl::Metrics::Metric->columns( Essential =>
	'hex_id',
	'package',
	'name',
	'version', # Metrics Package Version    - '1.04'
	'value',   # Metric Value               - '17', undef, 'Foo', '1.234'
	);

=pod

=head2 files @conditions

Because metrics are stored based on a document identifier rather than
by file name, if there are duplicate files indexed, one set of metrics
may related to more than one file.

The C<files> accessor searchs for all indexed C<::File> objects that have a
matching C<hex_id> to the C<::Metric> object.

=cut

sub files {
	my $self = shift;

	# Apply default search options to those passed
	my @params = ( hex_id => $self->hex_id, @_ );
	unless ( ref($params[-1]) eq 'HASH' ) {
		# Add standard ordering
		push @params, { order_by => 'file' };
	}

	# Execute the search
	Perl::Metrics::File->search( @params );
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

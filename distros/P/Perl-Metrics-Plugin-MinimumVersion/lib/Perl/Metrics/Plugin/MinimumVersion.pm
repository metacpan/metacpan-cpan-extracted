package Perl::Metrics::Plugin::MinimumVersion;

=pod

=head1 NAME

Perl::Metrics::Plugin::MinimumVersion - Perl::Metrics plugin for Perl::MinimumVersion

=head1 DESCRIPTION

This is a L<Perl::Metrics> "plugin" that generated the two primary metrics generated
by the L<Perl::MinimumVersion> module. These are the minimum explicit perl version
dependency, and the minimum syntax perl version dependency.

While this is an actual plugin to be used to real purposes, it provides a suitable
example of a simple plugin which brings functionality from a PPI-based module into
the larger L<Perl::Metrics> framework.

In addition, because the results could change based on changes to
L<Perl::MinimumVersion> this module also demonstrates the user of "versioned" metrics.

The C<metrics> method is overloaded to return an explicit list of metrics, with the
appropriate metric versions based on the version of L<Perl::MinimumVersion>.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp                 ();
use version              ();
use Perl::MinimumVersion 'PMV';
use base 'Perl::Metrics::Plugin';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

# The metrics are versioned, using the version of P:MV.
# This should cause the metrics to be automatically
# recalculated when P:MV is updated, without having
# to rerelease this dist as well.
sub metrics { {
	explicit => $Perl::MinimumVersion::VERSION,
	syntax   => $Perl::MinimumVersion::VERSION,
} }

=pod

=head2 metric_explicit

Provides the metric 'explicit', the minimum explicit version
provided as a normalized and serialized L<version> object.

=cut

sub metric_explicit {
	my ($self, $Document) = @_;
	my $pmv = PMV->new($Document) or Carp::croak(
		"Failed to create Perl::MinimumVersion object for Document "
		. $Document->hex_id
		);
	my $version = $pmv->minimum_explicit_version;
	return $version
		? $version->normal
		: $version;
}

=pod

=head2 metric_syntax

Provides the metric 'syntax', the minimum explicit version
provided as a normalized and serialized L<version> object.

=cut

sub metric_syntax {
	my ($self, $Document) = @_;
	my $pmv = PMV->new($Document) or Carp::croak(
		"Failed to create Perl::MinimumVersion object for Document "
		. $Document->hex_id
		);
	my $version = $pmv->minimum_syntax_version;
	return $version
		? $version->normal
		: $version;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics-Plugin-MinimumVersion>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics::Plugin>, L<Perl::Metrics>, L<Perl::MinimumVersion>,
L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

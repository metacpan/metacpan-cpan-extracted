package Perl::Metrics::Plugin::Core;

=pod

=head1 NAME

Perl::Metrics::Plugin::Core - The Core Perl Metrics Package

=head1 DESCRIPTION

This class provides a set of core metrics for Perl documents, based on
very simple code using only the core L<PPI> package.

=head1 METRICS

As with all L<Perl::Metrics::Plugin> packages, all metrics can be
referenced with the global identifier C<Perl::Metrics::Plugin::Core::metric>.

Metrics are listed as "datatype name".

=cut

use strict;
use base 'Perl::Metrics::Plugin';
use List::Util ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.09';
}

=pod

=head2 integer tokens 

The C<tokens> metric represents the total number of L<PPI::Token> objects
contained in the document.

For example, the following one-line document would have a C<tokens> metric
of 5 (assuming a single trailing newline)

  print "Hello World!\n";

=cut

sub metric_tokens {
	my ($self, $Document) = @_;
	scalar $Document->tokens;
}

=pod

=head2 integer significant_tokens

The C<significant_tokens> metric represents the total number of
C<significant> tokens contained in the document.

This filters out things like whitespace and comments, and refers (more or
less) to only the parts of the document that actually do something.

For more information on significance, see L<PPI::Element/significant>.

=cut

sub metric_significant_tokens {
	my ($self, $Document) = @_;
	scalar grep { $_->significant } $Document->tokens;
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

L<Perl::Metrics::Plugin>, L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

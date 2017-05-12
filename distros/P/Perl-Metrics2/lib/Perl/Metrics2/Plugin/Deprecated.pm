package Perl::Metrics2::Plugin::Deprecated;


use strict;
use Perl::Metrics2::Plugin ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.06';
	@ISA     = 'Perl::Metrics2::Plugin';
}

sub destructive { 0 }

sub process_metrics {
	my $self     = shift;
	my $document = shift;
	my %metric   = ();

	# Look for the use of $[
	$metric{array_first_element_index} = $document->find_any( sub {
		$_[1]->isa('PPI::Token::Magic')
		and
		$_[1]->content eq '$['
	} ) ? 1 : 0;

	return %metric;
}

1;

__END__

=pod

=head1 NAME

Perl::Metrics2::Plugin::Deprecated - Deprecated feature scanner

=head1 DESCRIPTION

This metrics class provides detection of various deprecated Perl features,
to help identify real-world uses of features that may break when these
features are eventually removed entirely.

=head1 METRICS

As with all L<Perl::Metrics::Plugin> packages, all metrics can be
referenced with the global identifier
C<Perl::Metrics::Plugin::Deprecated::metric>.

Metrics are listed as "datatype name".

=head2 boolean array_first_element_index

The C<array_first_element_index> flag is true if the file uses the
deprecated C<$[> magic variable.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Metrics2>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Metrics::Plugin>, L<Perl::Metrics>, L<PPI>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

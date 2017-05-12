package Perl::Metrics2::Plugin::Core;

use strict;
use bytes                  ();
use Perl::Metrics2::Plugin ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.06';
	@ISA     = 'Perl::Metrics2::Plugin';
}

sub process_metrics {
	my $self     = shift;
	my $document = shift;
	my %metric   = ();

	SCOPE: {
		my @tokens = $document->tokens;

		# The number of tokens in the file
		$metric{tokens} = scalar @tokens;

		# The number of significant tokens
		$metric{significant_tokens} = scalar grep { $_->significant } @tokens;
	}

	SCOPE: {
		my $string = $document->serialize;

		# The number of bytes in the file
		$metric{bytes} = bytes::length($string);

		# The number of lines in the file
		my $newlines =()= $string =~ /\n/g;
		$metric{lines} = $newlines + 1;
	}

	SCOPE: {
		# The final metrics (Source Lines of Code) is more complex (and destructive)
		$document->prune( sub {
			# Cull out the normal content
			! $_[1]->significant
			and
			# Cull out the high-volume whitespace tokens
			! $_[1]->isa('PPI::Token::Whitespace')
			and (
				$_[1]->isa('PPI::Token::Comment')
				or
				$_[1]->isa('PPI::Token::Pod')
				or
				$_[1]->isa('PPI::Token::End')
				or
				$_[1]->isa('PPI::Token::Data')
			)
		} );

		# Split the serialized for and find the number of non-blank lines
		$metric{sloc} = scalar grep { /\S/ } split /\n/, $document->serialize;
	}

	return %metric;
}
	
1;

=pod

=head1 NAME

Perl::Metrics2::Plugin::Core - The Core Perl Metrics Package

=head1 DESCRIPTION

This class provides a set of core metrics for Perl documents, based on
very simple code using only the core L<PPI> package.

=head1 METRICS

As with all L<Perl::Metrics::Plugin> packages, all metrics can be
referenced with the global identifier C<Perl::Metrics::Plugin::Core::metric>.

Metrics are listed as "datatype name".

=head2 integer bytes

The C<bytes> metric represents the number of bytes in the file.

=head2 integer lines

The C<lines> metric represents the number of raw lines in the file.

=head2 integer sloc

The C<sloc> metric represents Source Lines of Code. That is, raw lines
minus __END__ content, __DATA__ content, POD, comments and blank lines.

=head2 integer tokens 

The C<tokens> metric represents the total number of L<PPI::Token> objects
contained in the document.

For example, the following one-line document would have a C<tokens> metric
of 5 (assuming a single trailing newline)

  print "Hello World!\n";

=head2 integer significant_tokens

The C<significant_tokens> metric represents the total number of
C<significant> tokens contained in the document.

This filters out things like whitespace and comments, and refers (more or
less) to only the parts of the document that actually do something.

For more information on significance, see L<PPI::Element/significant>.

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

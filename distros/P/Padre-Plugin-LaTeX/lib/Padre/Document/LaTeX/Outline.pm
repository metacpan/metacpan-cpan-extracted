package Padre::Document::LaTeX::Outline;
BEGIN {
  $Padre::Document::LaTeX::Outline::VERSION = '0.13';
}

# ABSTRACT: LaTeX document support for Padre

use 5.008;
use strict;
use warnings;
use Padre::Task::Outline ();

our @ISA = 'Padre::Task::Outline';

sub find {
	my $self = shift;
	my $text = shift;

	# remove all comments
	$text =~ s/[^\\]%.*//g;

	warn "Text: $text\n";

	# Build the outline structure from the search results
	my @outline       = ();
	my $cur_pkg       = { name => 'latex file' };

	push @outline, $cur_pkg;

	return \@outline;
}

1;

__END__
=pod

=head1 NAME

Padre::Document::LaTeX::Outline - LaTeX document support for Padre

=head1 VERSION

version 0.13

=head1 AUTHORS

=over 4

=item *

Zeno Gantner <zenog@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Zeno Gantner, Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


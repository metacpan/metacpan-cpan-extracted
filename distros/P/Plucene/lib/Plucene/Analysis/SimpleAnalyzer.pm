package Plucene::Analysis::SimpleAnalyzer;

=head1 NAME 

Plucene::Analysis::SimpleAnalyzer - The simple analyzer

=head1 SYNOPSIS

	# isa Plucene::Analysis::Analyzer

	my Plucene::Analysis::LowerCaseTokenizer $an 
		= Plucene::Analysis::SimpleAnalyzer->new(@args);

=head1 DESCRIPTION

This is an Analyzer that filters LetterTokenizer with LowerCaseFilter.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::Analyzer';

use Plucene::Analysis::LowerCaseTokenizer;

=head2 tokenstream

	my Plucene::Analysis::LowerCaseTokenizer $an 
		= Plucene::Analysis::SimpleAnalyzer->new(@args);

This creates a TokenStream which tokenizes all the text in the provided 
Reader.

=cut

sub tokenstream {
	my $self = shift;
	return Plucene::Analysis::LowerCaseTokenizer->new(@_);
}

1;

package Plucene::Analysis::WhitespaceAnalyzer;

=head1 NAME 

Plucene::Analysis::WhitespaceAnalyzer - white space analyzer

=head1 SYNOPSIS

	# isa Plucene::Analysis::Analyzer

	my Plucene::Analysis::WhitespaceTokenizer $wt 
		= Plucene::Analysis::WhitespaceAnalyzer->new(@args);
		
=head1 DESCRIPTION

This is an Analyzer that uses WhitespaceTokenizer.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::Analyzer';
use Plucene::Analysis::WhitespaceTokenizer;

=head2 tokenstream

	my Plucene::Analysis::WhitespaceTokenizer $wt 
		= Plucene::Analysis::WhitespaceAnalyzer->new(@args);

Creates a TokenStream which tokenizes all the text in the provided Reader.

=cut

sub tokenstream {
	my $self = shift;
	return Plucene::Analysis::WhitespaceTokenizer->new(@_);
}

1;

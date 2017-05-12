package Plucene::Analysis::Standard::StandardAnalyzer;

=head1 NAME 

Plucene::Analysis::Standard::StandardAnalyzer - standard analyzer

=head1 SYNOPSIS

	my Plucene::Analysis::Stopfilter $sf = 
		Plucene::Analysis::Standard::StandardAnalyzer->tokenstream(@args);
		
=head1 DESCRIPTION

The standard analyzer, built with a list of stop words.

This list of stop words are:

	"a",     "and",  "are",   "as",    "at",   "be",   "but",  "by",
	"for",   "if",   "in",    "into",  "is",   "it",   "no",   "not",
	"of",    "on",   "or",    "s",     "such", "t",    "that", "the",
	"their", "then", "there", "these", "they", "this", "to",   "was",
	"will",  "with"
	
=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::Analyzer';

use Plucene::Analysis::Standard::StandardTokenizer;
use Plucene::Analysis::StopFilter;

my @stopwords = (
	"a",     "and",  "are",   "as",    "at",   "be",   "but",  "by",
	"for",   "if",   "in",    "into",  "is",   "it",   "no",   "not",
	"of",    "on",   "or",    "s",     "such", "t",    "that", "the",
	"their", "then", "there", "these", "they", "this", "to",   "was",
	"will",  "with"
);

=head2 tokenstream

	my Plucene::Analysis::Stopfilter $sf = 
		Plucene::Analysis::Standard::StandardAnalyzer->tokenstream(@args);

=cut

sub tokenstream {
	my $class = shift;
	return Plucene::Analysis::StopFilter->new({
			input    => Plucene::Analysis::Standard::StandardTokenizer->new(@_),
			stoplist => \@stopwords
		});
}

1;

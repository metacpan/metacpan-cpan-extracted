package Plucene::Analysis::StopAnalyzer;

=head1 NAME 

Plucene::Analysis::StopAnalyzer - the stop-word analyzer

=head1 SYNOPSIS

	my Plucene::Analysis::StopFilter $sf 
		= Plucene::Analysis::StopAnalyzer->new(@args);

=head1 DESCRIPTION

Filters LetterTokenizer with LowerCaseFilter and StopFilter.

=head1 METHODS

=cut

use strict;
use warnings;

use Plucene::Analysis::LowerCaseTokenizer;
use Plucene::Analysis::StopFilter;
use base 'Plucene::Analysis::Analyzer';

my @stopwords = (
	"a",     "and",  "are",   "as",    "at",   "be",   "but",  "by",
	"for",   "if",   "in",    "into",  "is",   "it",   "no",   "not",
	"of",    "on",   "or",    "s",     "such", "t",    "that", "the",
	"their", "then", "there", "these", "they", "this", "to",   "was",
	"will",  "with"
);

=head2 tokenstream

	my Plucene::Analysis::StopFilter $sf 
		= Plucene::Analysis::StopAnalyzer->new(@args);

Filters LowerCaseTokenizer with StopFilter.

=cut

sub tokenstream {
	my $self = shift;
	return Plucene::Analysis::StopFilter->new({
			input    => Plucene::Analysis::LowerCaseTokenizer->new(@_),
			stoplist => \@stopwords
		});
}

1;

package Plucene::Analysis::PorterStemFilter;

=head1 NAME

Plucene::Analysis::PorterStemFilter - Porter stemming on the token stream

=head1 SYNOPSIS

	# isa Plucene::Analysis:::TokenFilter
	
	my $token = $porter_stem_filter->next;

=head1 DESCRIPTION

This class transforms the token stream as per the Porter stemming algorithm.

Note: the input to the stemming filter must already be in lower case, so you 
will need to use LowerCaseFilter or LowerCaseTokenizer farther down the 
Tokenizer chain in order for this to work properly!

The Porter Stemmer implements Porter Algorithm for normalization of English 
words by stripping their extensions and is used to generalize the searches. 
For example, the Porter algorithm maps both 'search' and 'searching' 
(as well as 'searchnessing') to 'search' such that a query for 'search' will 
also match documents that contains the word 'searching'.

Note that the Porter algorithm is specific to the English language and may give 
unpredictable results for other languages. Also, make sure to use the same 
analyzer during the indexing and the searching.

You can find more information on the Porter algorithm at 
www.tartarus.org/~martin/PorterStemmer. 

A nice online demonstration of the Porter algorithm is available at 
www.scs.carleton.ca/~dquesnel/java/stuff/PorterApplet.html. 

=head1 METHODS

=cut

use strict;
use warnings;

use Lingua::Stem::En;
Lingua::Stem::En::stem_caching({ -level => 2 });

use base 'Plucene::Analysis::TokenFilter';

=head2 next

	my $token = $porter_stem_filter->next;

Returns the next input token, after being stemmed.

=cut

sub next {
	my $self = shift;
	my $t = $self->input->next or return;
	$t->text(@{ Lingua::Stem::En::stem({ -words => [ $t->text ] }) });
	return $t;
}

1;

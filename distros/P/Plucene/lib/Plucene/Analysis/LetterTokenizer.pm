package Plucene::Analysis::LetterTokenizer;

=head1 NAME 

Plucene::Analysis::LetterTokenizer - Letter tokenizer

=head1 SYNOPSIS

	# isa Plucene::Analysis::CharTokenizer

=head1 DESCRIPTION

This is the letter tokenizer class, which divides text at non-letters.

Note: this does a decent job for most European languages, but does a 
terrible job for some Asian languages, where words are not separated 
by spaces

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::CharTokenizer';

sub token_re { qr/[[:alpha:]]+/ }

1;

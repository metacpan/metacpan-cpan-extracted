package Plucene::Analysis::WhitespaceTokenizer;

=head1 NAME 

Plucene::Analysis::WhitespaceTokenizer - white space tokenizer

=head1 SYNOPSIS

	# isa Plucene::Analysis::CharTokenizer

=head1 DESCRIPTION

A WhitespaceTokenizer is a tokenizer that divides text at whitespace. 
Adjacent sequences of non-Whitespace characters form tokens.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::CharTokenizer';

sub token_re { qr/\S+/ }

1;

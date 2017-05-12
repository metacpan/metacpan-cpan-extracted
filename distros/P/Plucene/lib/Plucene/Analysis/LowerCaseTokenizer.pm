package Plucene::Analysis::LowerCaseTokenizer;

=head1 NAME 

Plucene::Analysis::LowerCaseTokenizer - tokenizer which also lower cases text

=head1 SYNOPSIS

	# isa Plucene::Analysis::LetterTokenizer

=head1 DESCRIPTION

This tokenizer divides text at non letters, and also lower cases them.

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Plucene::Analysis::LetterTokenizer';

sub normalize { lc $_[1] }

1;

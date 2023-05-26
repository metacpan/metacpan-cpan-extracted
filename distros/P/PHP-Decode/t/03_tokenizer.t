# Tests: tokenizer
#
# see: more tokenizer tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use PHP::Decode::Tokenizer;

plan tests => 2;

package SymTokenizer;
use base 'PHP::Decode::Tokenizer';

my @tok;

sub new {
	my ($class, %args) = @_;
	return $class->SUPER::new(%args);
}

sub add {
	my ($tab, $sym) = @_;
	push(@tok, $sym);
}

sub add_white {
	my ($tab, $sym) = @_;
}

package main;

my $line = '<?php echo "test"; ?>';
my $parser = SymTokenizer->new();

my $quote = $parser->tokenize_line($line);
is($quote, undef, 'tokenize quote');

my $res = join(' ', @tok);
is($res, "<?php echo test ; ?>", 'tokenize result');


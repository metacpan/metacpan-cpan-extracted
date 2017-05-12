#!perl
use strict;
use warnings;

use Test::More tests => 5;
use RTF::Tokenizer;

my $tokenizer = RTF::Tokenizer->new();

$tokenizer->read_string("{Ich nom es Peter}More\n\t text!");

ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
    'Groups opens' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'Ich nom es Peter', '' ] ),
    'Read text' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
    'Groups closes' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', "More\t text!", '' ] ),
    'Read text' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'eof', 1, 0 ] ), 'EOF' );

#!perl
use strict;
use warnings;

use Test::More tests => 15;
use RTF::Tokenizer;

my $tokenizer = RTF::Tokenizer->new();

$tokenizer->read_string(
    qq?{\\\rIch nom es Peter\\\n\\and-50\\rtf1 a}\\I0\\rock\\*5\\'acMore text!?
);

ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
    'Groups opens' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'par', '' ] ),
    'Read \\r properly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'Ich nom es Peter', '' ] ),
    'Read text' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'par', '' ] ),
    'Read \\n properly' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'and', '-50' ] ),
    'Read control' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
    'Read control + param terminated by a-z' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'a', '' ] ), 'Read text' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
    'Groups closes' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'I', '0' ] ),
    'Read control' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rock', '' ] ),
    'Read control' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', '*', '' ] ),
    'Read control' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', '5', '' ] ), 'Read text' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', "'", 'ac' ] ),
    'Read control' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'More text!', '' ] ),
    'Read text' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'eof', 1, 0 ] ), 'EOF' );

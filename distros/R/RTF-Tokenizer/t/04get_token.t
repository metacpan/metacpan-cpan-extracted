#!perl
use strict;
use warnings;

use Test::More tests => 3;
use RTF::Tokenizer;

my $tokenizer = RTF::Tokenizer->new();

$tokenizer->read_string("{\n}\n");

ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
    'Groups opens' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
    'Groups closes' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'eof', 1, 0 ] ), 'EOF' );

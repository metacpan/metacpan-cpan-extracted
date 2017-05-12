#!perl
use strict;
use warnings;

use RTF::Tokenizer;
use Test::More tests => 9;

my $string = "{\\rtf1 Hi there\cM asdfi \cMSee ya!abc\\la}\\bin5 ab";

my $tokenizer = RTF::Tokenizer->new( string => $string );

ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
    'Groups opens' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
    'RTF v1' );
ok( eq_array(
        [ $tokenizer->get_token() ],
        [ 'text', "Hi there asdfi See ya!abc", '' ]
    ),
    'Read text' );

$tokenizer->put_token( 'asdf', 'fdsa', 5 );
$tokenizer->put_token( 'trtr', 'jgjg', 'g' );
$tokenizer->put_token( 324,    432,    'asdfasdf' );

ok( eq_array( [ $tokenizer->get_token() ], [ 324, 432, 'asdfasdf' ] ),
    'put test 1' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'trtr', 'jgjg', 'g' ] ),
    'put test 2' );
ok( eq_array( [ $tokenizer->get_token() ], [ 'asdf', 'fdsa', 5 ] ),
    'put test 3' );

ok( eq_array( [ $tokenizer->get_token() ], [ 'control', "la", '' ] ),
    'Read text' );

is( $tokenizer->debug(),  "}\\bin5 ab", "default debug seems to work" );
is( $tokenizer->debug(5), "}\\bin",     "debug(5) seems to work" );


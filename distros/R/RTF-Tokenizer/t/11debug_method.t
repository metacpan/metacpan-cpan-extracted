#!perl
use strict;
use warnings;

use RTF::Tokenizer;
use Test::More tests => 5;

SKIP: {
    eval { require IO::Scalar };
    skip "IO::Scalar not installed", 5 if $@;

    my $xstring = 'x' x 500;

    my $stringMAC = "{\\rtf1 Hi there\cM $xstring \cMSee ya!abc\\la}\\bin5 ab";
    my $fhMAC     = new IO::Scalar \$stringMAC;

    my $tokenizer = RTF::Tokenizer->new( file => $fhMAC );

    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
        'Groups opens' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
        'RTF v1' );
    ok( eq_array(
            [ $tokenizer->get_token() ],
            [ 'text', "Hi there $xstring See ya!abc", '' ]
        ),
        'Read text' );

    is( $tokenizer->debug(),  "\\la}\\bin5 ab", "default debug seems to work" );
    is( $tokenizer->debug(5), "\\la}\\",        "debug(5) seems to work" );
}

#!perl
use strict;
use warnings;

use Test::More tests => 23;
use RTF::Tokenizer;

SKIP: {
    eval { require IO::Scalar };
    skip "IO::Scalar not installed", 23 if $@;

    my $tokenizer = RTF::Tokenizer->new();

    my $xstring = 'x' x 500;

    my $stringMAC = "{\\rtf1 Hi there\cM$xstring\cM\tSee ya!}";
    my $stringNIX = "{\\rtf1 Lo there\cJ $xstring \cJSee ya!}";
    my $stringWIN = "{\\rtf1 Ho there\cM\cJ $xstring \cM\cJSee ya!}";

    my $stringPAR = "{\\rtf1 Lo there\cJ $xstring \cJSee ya!\\\cJ}";

    my $fhMAC = new IO::Scalar \$stringMAC;
    my $fhNIX = new IO::Scalar \$stringNIX;
    my $fhWIN = new IO::Scalar \$stringWIN;
    my $fhPAR = new IO::Scalar \$stringPAR;

    # Set $/ to something outrageous
    my $saved = $/;
    $/ = 'x';

    $tokenizer->{_FILEHANDLE} = $fhMAC;
    $tokenizer->{_BUFFER}     = '';
    $tokenizer->_line_endings;
    is( $tokenizer->{_RS}, 'Macintosh', 'Mac endings read right' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
        'Groups opens' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
        'RTF v1' );
    ok( eq_array(
            [ $tokenizer->get_token() ],
            [ 'text', "Hi there" . $xstring . "\tSee ya!", '' ]
        ),
        'Read text' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
        'Groups closes' );

    is( $/, 'x', 'RS still correct' );

    $tokenizer->{_FILEHANDLE} = $fhNIX;
    $tokenizer->{_BUFFER}     = '';
    $tokenizer->_line_endings;
    is( $tokenizer->{_RS}, 'UNIX', 'UNIX endings read right' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
        'Groups opens' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
        'RTF v1' );
    ok( eq_array(
            [ $tokenizer->get_token() ],
            [ 'text', "Lo there $xstring See ya!", '' ]
        ),
        'Read text' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
        'Groups closes' );

    is( $/, 'x', 'RS still correct' );

    $tokenizer->{_FILEHANDLE} = $fhWIN;
    $tokenizer->{_BUFFER}     = '';
    $tokenizer->_line_endings;
    is( $tokenizer->{_RS}, 'Windows', 'Windows endings read right' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
        'Groups opens' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
        'RTF v1' );
    ok( eq_array(
            [ $tokenizer->get_token() ],
            [ 'text', "Ho there $xstring See ya!", '' ]
        ),
        'Read text' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
        'Groups closes' );

    is( $/, 'x', 'RS still correct' );

    $/ = $saved;

    $tokenizer->read_file($fhPAR);
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
        'Groups opens' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
        'RTF v1' );
    ok( eq_array(
            [ $tokenizer->get_token() ],
            [ 'text', "Lo there $xstring See ya!", '' ]
        ),
        'Read text' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'par', '' ] ),
        'Read a paragraph' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
        'Groups closes' );
}

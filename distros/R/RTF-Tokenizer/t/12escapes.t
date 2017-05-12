#!perl
use strict;
use warnings;

use RTF::Tokenizer;
use Test::More tests => 9;

SKIP: {
    eval { require IO::Scalar };
    skip "IO::Scalar not installed", 9 if $@;

    my $xstring = 'x' x 500;

    my $stringMAC = "{\\rtf1 Hi there\cM $xstring \cMSee ya!abc\\'aa}\\_";
    my $fhMAC     = new IO::Scalar \$stringMAC;

    my $tokenizer =
        RTF::Tokenizer->new( file => $fhMAC, note_escapes => 'true' );

    ok( $tokenizer->{_NOTE_ESCAPES}, 'Note escapes flag set' );

    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
        'Groups opens' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
        'RTF v1' );
    ok( eq_array(
            [ $tokenizer->get_token() ],
            [ 'text', "Hi there $xstring See ya!abc", '' ]
        ),
        'Read text' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'escape', "'", 'aa' ] ),
        'Hex char' );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
        'Group closes' );
    ok( !$tokenizer->{_TEMP_ESCAPE_FLAG}, "Temp flag is unset" );
    ok( eq_array( [ $tokenizer->get_token() ], [ 'escape', '_', '' ] ),
        'Escape found' );
    ok( !$tokenizer->{_TEMP_ESCAPE_FLAG}, 'Temp flag is still unset' );
}

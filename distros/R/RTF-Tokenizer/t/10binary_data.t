#!perl
use strict;
use warnings;

use RTF::Tokenizer;
use Test::More tests => 18;

SKIP: {

    eval { require IO::Scalar };
    skip "IO::Scalar not installed", 18 if $@;

    my $x_string = 'x' x 500;

    my $rtf_data =
        "{\\rtf1 Hi there\cM $x_string \cMSee ya!\\bin6}}}}\n}abc\\la}\\bin5 ab";

    # Take a copy for the FH
    my $rtf_data_for_fh = $rtf_data;
    my $fh              = new IO::Scalar \$rtf_data_for_fh;

    for my $args ( [ string => $rtf_data ], [ file => $fh ] ) {

        my $tokenizer = RTF::Tokenizer->new(@$args);

        ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 1, '' ] ),
            'Groups opens' );
        ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'rtf', 1 ] ),
            'RTF v1' );
        ok( eq_array(
                [ $tokenizer->get_token() ],
                [ 'text', "Hi there $x_string See ya!", '' ]
            ),
            'Read text' );
        ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'bin', '6' ] ),
            'Read the binary control' );
        ok( eq_array( [ $tokenizer->get_token() ], [ 'text', "}}}}\n}", '' ] ),
            'Read binary data' );
        ok( eq_array( [ $tokenizer->get_token() ], [ 'text', 'abc', '' ] ),
            'Read text' );
        ok( eq_array( [ $tokenizer->get_token() ], [ 'control', 'la', '' ] ),
            'Read control' );
        ok( eq_array( [ $tokenizer->get_token() ], [ 'group', 0, '' ] ),
            'Groups closes' );

        local $@ = undef;
        eval '$tokenizer->get_token()';
        my $error = $@;

        like(
            $error,
            qr/^\\bin is asking for 5 characters, but there are only 2 left/,
            'Too few characters causes error' );

    }

}
